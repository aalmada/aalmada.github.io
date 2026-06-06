---
layout: post
read_time: true
show_date: true
title: "Implementing Passkeys with .NET 10"
date: 2026-01-24
img_path: /assets/img/posts/20260124
image: /assets/img/posts/20260124/door.jpg
tags: [dotnet, passkeys, webauthn, security, aspnetcore]
category: security
meta_description: "A technical guide for .NET developers on integrating native WebAuthn passkey support introduced in .NET 10, including user enumeration and lockout prevention."
---

We finally have a robust and practical alternative to passwords. For years, we've forced users to juggle complex strings of characters, special symbols, and numbers, only to have them phished or leaked in the next big data breach. They are the single weakest link in modern security.

But with the arrival of **.NET 10**, the game has changed. Microsoft has introduced native support for **Passkeys (WebAuthn)** as a first-class citizen in ASP.NET Core Identity. This isn't just a minor update; it's a fundamental shift in how we handle authentication. In this post, I'll dive into how I integrated these capabilities into the [BookStore project](https://aalmada.github.io/BookStore/) and why every .NET developer should be paying attention.

## Why Passkeys?

The fundamental flaw of a password is that it's a **shared secret**. Both the user and the server know it (or a hash of it). If an attacker gets that secret, they *are* the user.

Passkeys flip this model on its head using asymmetric cryptography. When a user registers:
1.  **The Private Key**: Stays locked in the device's Secure Enclave or TPM. It never leaves the device.
2.  **The Public Key**: Is sent to your server and stored in your database.

Authentication happens by your server sending a **challenge** that the user's device signs with the private key. Your server then verifies that signature using the public key. No secrets are ever shared, making it inherently phishing-resistant.

If you want a visual deep dive into how this all works together, I highly recommend watching this [excellent explanation of passkeys](https://www.youtube.com/watch?v=xYfiOnufBSk).

### Passkeys are NOT just 2FA

There’s a common misconception that passkeys are just a fancy version of an Authenticator app or a security key used as a second factor. While they can serve that role, in **.NET 10**, we can use them to replace passwords entirely.

In the **BookStore** project, I've implemented support for **passwordless accounts**. A user can sign up with just an email, register their passkey, and from that point on, their "login" is simply a fingerprint or face scan. No password field, no "Forgot Password" stress.

However, this doesn't mean passwords are gone for good. The project supports a **hybrid approach**:
- **Existing Password Accounts**: Users who signed up with a password can add one or more passkeys to their account for a faster login experience.
- **Passkey-First Accounts**: Users who started with a passkey can always choose to add a password later, providing an alternative way to log in on devices that might not support WebAuthn yet.

## The WebAuthn Handshake: Implementation

Implementing this in .NET 10 involves two main flows: **Attestation** (Registration) and **Assertion** (Login).

### 1. Attestation (Registration)

Registration starts with the server generating `PublicKeyCredentialCreationOptions`. This includes a unique challenge, information about the Relying Party (your app), and the user entity.

A critical security feature I've implemented in `PasskeyEndpoints.cs` is **User Enumeration Protection**. If an attacker tries to register an email that is already taken, a naive implementation might return an error immediately, revealing that the user exists. Instead, we generate a valid challenge for a "dummy" user:

```csharp
// If anonymous, we are in "Register new Account" flow
var conflictingUser = await userManager.FindByEmailAsync(request.Email);
if (conflictingUser is not null)
{
    // Security: Don't return error to prevent user enumeration.
    // Instead, proceed to generate options for a dummy user.
    // The registration will fail at the final step (masked).
}

var newUserEntity = new PasskeyUserEntity { Id = newUserId, Name = request.Email, ... };
var options = await signInManager.MakePasskeyCreationOptionsAsync(newUserEntity);
```

When the client returns the `CredentialJson`, we use `signInManager.PerformPasskeyAttestationAsync(request.CredentialJson)` to validate the signature and extract the new credential details.

### 2. Assertion (Login)

Login is where the magic happens. The server sends a challenge, and the authenticator returns a signed response. The `SignInManager` now has a dedicated method for this:

```csharp
var result = await signInManager.PasskeySignInAsync(request.CredentialJson);

if (result.Succeeded)
{
    // The WebAuthn response contains a 'userHandle' which is our User ID.
    // We decode it from Base64URL to find the specific ApplicationUser.
    string? userId = DecodeBase64UrlToString(userHandleBase64);
    var user = await userManager.FindByIdAsync(userId);
    
    return await IssueTokens(user, ...);
}
```

## Email Verification and Identity

While a passkey proves that the user has possession of a registered device, it doesn't inherently prove that they own the email address they've provided during a new registration. In a passwordless world, verifying email ownership is even more critical because the email address is often the primary way to recover an account if all passkeys are lost.

In the **BookStore** project, I've ensured that the registration flow respects the `RequireConfirmedEmail` setting:

1.  **Registration**: When a user registers with a passkey, we check if email verification is required. If it is, we generate a confirmation token and send it via a background worker using the Wolverine message bus.
2.  **Restricted Access**: The user is created in the database, but they are not automatically logged in until they confirm their email.
3.  **Sign-in Guard**: Even if a user attempts to log in with their newly created passkey, the `IssueTokens` logic uses `signInManager.CanSignInAsync(user)`, which rejects anyone with an unconfirmed email (if required by configuration).
4.  **Automated Cleanup**: To keep the database clean and prevent "ghost" accounts, I've implemented a scheduled job using **Wolverine** that periodically removes unverified accounts that haven't been confirmed within a certain window.

This ensures that while the *authentication* is passwordless, the *identity* remains verified and secure.

## Management and the "Lockout" Safeguard

Allowing users to manage their passkeys is essential. A user might have a passkey on their MacBook and another on their iPhone. However, this introduces a new risk: what if they delete their only passkey?

In the **BookStore** implementation, I've added a hard check in the delete endpoint to ensure a user always has a way back in. If they don't have a password set, they are **prohibited from deleting their last passkey**:

```csharp
var passkeys = await passkeyStore.GetPasskeysAsync(user, cancellationToken);
if (passkeys.Count <= 1 && !await userManager.HasPasswordAsync(user))
{
    return Result.Failure(Error.Validation("Cannot delete your only passkey. You would be locked out.")).ToProblemDetails();
}
```

## Defense in Depth: Security Safeguards

Authentication endpoints are prime targets for attackers. Beyond the WebAuthn specific protections, I've implemented several "Defense in Depth" layers across the entire authentication stack in the **BookStore** project:

### 1. User Enumeration Protection
Whether a user is signing up, logging in, or resetting their password, the API response should never reveal if an email address exists in the system. 
- During registration, we return a successful "Check your email" message even if the account already exists.
- In the `ResendVerification` endpoint, we return a generic message: *"If an account exists, a link has been sent"*, regardless of whether the user exists or is already verified.

### 2. Rate Limiting and Cooldowns
To mitigate brute-force and denial-of-service attacks:
- All authentication endpoints are protected by a global **Rate Limiting** policy (`AuthPolicy`).
- The email verification system enforces a **60-second cooldown** between requests. If a user (or bot) hammers the resend button, the server will log the attempt but silently ignore it, returning a success response to avoid timing attacks.

### 3. Token Security and Rotation
Our JWT implementation doesn't just issue tokens; it manages their lifecycle:
- **Refresh Token Rotation**: Every time a refresh token is used, it is invalidated and a new one is issued (rotation).
- **Token Pruning**: We only keep the 5 most recent refresh tokens per user, preventing token accumulation and limiting the window of exposure for stolen devices.
- **Tenant Isolation**: In our multi-tenant architecture, refresh tokens are cryptographically bound to a specific `TenantId`. A token stolen from one tenant cannot be used to gain access to another.

### 4. Lockout Policy
Traditional password attempts are strictly monitored. After several failed attempts, the `SignInManager` locks the account for a cooling-off period, preventing automated brute-force attacks.

## The Frontend Bridge: Blazor & JS Interop

While .NET 10 handles the heavy lifting on the server, the browser's `navigator.credentials` API is only accessible via JavaScript. In the **BookStore** Blazor project, I've bridged this gap using a small JS interop layer.

The Blazor component calls a wrapper that simplifies the complex WebAuthn objects into JSON strings that are easy for .NET to serialize:

```javascript
window.passkey = {
    register: async (optionsJson) => {
        const options = parseOptions(optionsJson);
        const credential = await navigator.credentials.create({ publicKey: options });
        return serializeCredential(credential);
    },
    // ... same for login
};
```

On the Razor page, the interaction is clean and asynchronous:

```csharp
var optionsResult = await PasskeyService.GetCreationOptionsAsync();
var credentialJson = await JS.InvokeAsync<string>("passkey.register", optionsResult.Value);
var result = await PasskeyService.RegisterPasskeyAsync(credentialJson);
```



## Behind the Scenes: IUserPasskeyStore

All of this relies on the new `IUserPasskeyStore<TUser>` interface. This is where you bridge the gap between the Identity framework and your database. In my case, I'm using **Marten** (PostgreSQL) to store the passkey data:

```csharp
public interface IUserPasskeyStore<TUser> : IUserStore<TUser> where TUser : class
{
    Task AddOrUpdatePasskeyAsync(TUser user, PasskeyCredential credential, CancellationToken ct);
    Task<IReadOnlyList<PasskeyCredential>> GetPasskeysAsync(TUser user, CancellationToken ct);
    Task RemovePasskeyAsync(TUser user, byte[] credentialId, CancellationToken ct);
}
```

## Conclusion

The native support for WebAuthn in **.NET 10** is a massive win for the ecosystem. It removes the need for complex third-party dependencies and brings world-class security to the standard Identity stack. 

By implementing passkeys, you aren't just adding a feature; you're providing a premium, frustration-free experience for your users while simultaneously hardening your application against the most common modern attacks.

The full implementation details, including the Blazor components and the API endpoints, are available in the [BookStore repository](https://aalmada.github.io/BookStore/). It's time to stop talking about a passwordless future and start building it.
