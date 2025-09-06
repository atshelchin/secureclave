import { WebAuthnP256, P256, PublicKey, Signature, Hex } from 'ox'

// 从 iOS 应用复制的数据
const publicKey_passkeys = "0x021ec9330bfd6d3e56ba5d00000000fbfc3007154e4ecc8c0b6e020557d7bd0014"
const challenge = "0x863d37e0f4b8b426788d4d829ad01c830cca5639ddf434bc38d34afde3d673c0"
const authenticatorData = "0xa49150052d03f21b294fe0778b7d4e8a7cd53c92406e021ec9330bfd6d3e56ba1d00000000"
const clientDataJSON = "eyJ0eXBlIjoid2ViYXV0aG4uZ2V0IiwiY2hhbGxlbmdlIjoiaGowMzRQUzR0Q1o0alUyQ210QWNnd3pLVmpuZDlEUzhPTk5LX2VQV2M4QSIsIm9yaWdpbiI6Imh0dHBzOi8vc2hlbGNoaW4yMDI1LmdpdGh1Yi5pbyJ9"
const signature_passkeys = "0x30440220219026626c9a5d2d635bed493005902678d6037331755671087aec42a03785c7022032691f02e010047d5d78668833f125a2337eba890618ec20a930aac86aca043b"

console.log("🔍 Debugging WebAuthn Verification")
console.log("=====================================")

// 1. 检查公钥格式
console.log("\n1️⃣ Public Key Analysis:")
console.log(`   Length: ${publicKey_passkeys.length / 2 - 1} bytes`)
console.log(`   First byte: ${publicKey_passkeys.substring(2, 4)}`)
if (publicKey_passkeys.substring(2, 4) === '02' || publicKey_passkeys.substring(2, 4) === '03') {
    console.log("   ⚠️  This is a COMPRESSED public key (33 bytes)")
    console.log("   ❌ ox library expects UNCOMPRESSED format (65 bytes, starting with 0x04)")
    
    // 尝试转换为未压缩格式（需要额外的库）
    console.log("\n   💡 Solution: iOS app needs to extract the uncompressed public key")
} else if (publicKey_passkeys.substring(2, 4) === '04') {
    console.log("   ✅ This is an UNCOMPRESSED public key")
}

// 2. 检查 authenticatorData
console.log("\n2️⃣ Authenticator Data Analysis:")
console.log(`   Length: ${(authenticatorData.length - 2) / 2} bytes`)
if ((authenticatorData.length - 2) / 2 < 37) {
    console.log("   ❌ Too short! Minimum is 37 bytes")
} else {
    console.log("   ✅ Length is valid")
    
    // 解析 flags
    const flags = parseInt(authenticatorData.substring(66, 68), 16)
    console.log(`   Flags: 0x${authenticatorData.substring(66, 68)}`)
    console.log(`   - User Present (UP): ${(flags & 0x01) !== 0}`)
    console.log(`   - User Verified (UV): ${(flags & 0x04) !== 0}`)
}

// 3. 检查 clientDataJSON
console.log("\n3️⃣ Client Data JSON Analysis:")
const clientData = JSON.parse(Buffer.from(clientDataJSON, 'base64').toString())
console.log("   Decoded:", JSON.stringify(clientData, null, 2))

// 检查 challenge 是否匹配
const challengeFromClient = Buffer.from(clientData.challenge, 'base64url').toString('hex')
console.log(`   Challenge from client: 0x${challengeFromClient}`)
console.log(`   Expected challenge: ${challenge}`)
if (`0x${challengeFromClient}` === challenge) {
    console.log("   ✅ Challenge matches!")
} else {
    console.log("   ❌ Challenge mismatch!")
}

// 查找索引
const clientDataStr = Buffer.from(clientDataJSON, 'base64').toString()
const typeIndex = clientDataStr.indexOf('"type"')
const challengeIndex = clientDataStr.indexOf('"challenge"')
console.log(`   Type index: ${typeIndex}`)
console.log(`   Challenge index: ${challengeIndex}`)

// 4. 尝试验证（即使公钥格式不对）
console.log("\n4️⃣ Verification Attempt:")
console.log("   Note: This will fail if public key is compressed")

try {
    // 尝试不同的配置
    const configs = [
        { hash: false, desc: "hash: false (recommended for WebAuthn)" },
        { hash: true, desc: "hash: true" }
    ]
    
    for (const config of configs) {
        console.log(`\n   Testing with ${config.desc}:`)
        try {
            const result = await WebAuthnP256.verify({
                hash: config.hash,
                metadata: {
                    clientDataJSON,
                    authenticatorData,
                    typeIndex,
                    challengeIndex,
                    userVerificationRequired: (parseInt(authenticatorData.substring(66, 68), 16) & 0x04) !== 0,
                },
                challenge: challenge,
                publicKey: PublicKey.fromHex(publicKey_passkeys),
                signature: Signature.fromDerHex(signature_passkeys),
            })
            console.log(`   Result: ${result ? '✅ VALID' : '❌ INVALID'}`)
        } catch (error) {
            console.log(`   Error: ${error.message}`)
        }
    }
} catch (error) {
    console.log(`   Fatal error: ${error.message}`)
}

console.log("\n=====================================")
console.log("📌 Summary:")
console.log("The main issue is likely the compressed public key format.")
console.log("iOS needs to extract the UNCOMPRESSED public key (65 bytes, starting with 0x04)")
console.log("from the attestation object during Passkey creation.")