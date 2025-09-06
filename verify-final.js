import { WebAuthnP256, PublicKey, Signature } from 'ox'

// 从 iOS 应用复制的数据
const publicKeyHex = "0x04f7c5d7e5d95011c9d1270e1f01d08334b6343c32a6c09e90d63c077af31aa1ee6a92c9bbf0cf30d142bae019b95130dc534ecaf188de62ab8fb32a9c2973b100"
const signature = "0x3045022072157a0e157346183e64c9d24d699ffac7dda22460aee4b20b62b785a6fbe05d022100bcb1c4effe18240ebf179c0f48c55ca0630727dc6a38f14585919e1ed3545d02"
const challenge = "0x863d37e0f4b8b426788d4d829ad01c830cca5639ddf434bc38d34afde3d673c0"
const authenticatorData = "0xa49150052d03f21b294fe0778b7d4e8a7cd53c92406e021ec9330bfd6d3e56ba1d00000000"
const clientDataJSON = "eyJ0eXBlIjoid2ViYXV0aG4uZ2V0IiwiY2hhbGxlbmdlIjoiaGowMzRQUzR0Q1o0alUyQ210QWNnd3pLVmpuZDlEUzhPTk5LX2VQV2M4QSIsIm9yaWdpbiI6Imh0dHBzOi8vc2hlbGNoaW4yMDI1LmdpdGh1Yi5pbyJ9"

console.log("🔍 WebAuthn 签名验证")
console.log("=" .repeat(50))

// 1. 检查公钥
console.log("\n1️⃣ 公钥分析:")
console.log(`   长度: ${(publicKeyHex.length - 2) / 2} 字节`)
console.log(`   格式: ${publicKeyHex.substring(2, 4) === '04' ? '✅ 未压缩格式' : '❌ 错误格式'}`)
console.log(`   X: ${publicKeyHex.substring(4, 68)}`)
console.log(`   Y: ${publicKeyHex.substring(68, 132)}`)

// 2. 检查 authenticatorData
console.log("\n2️⃣ Authenticator Data:")
console.log(`   长度: ${(authenticatorData.length - 2) / 2} 字节`)
const flags = parseInt(authenticatorData.substring(66, 68), 16)
console.log(`   Flags: 0x${authenticatorData.substring(66, 68)}`)
console.log(`   - User Present (UP): ${(flags & 0x01) !== 0}`)
console.log(`   - User Verified (UV): ${(flags & 0x04) !== 0}`)

// 3. 解析 clientDataJSON
console.log("\n3️⃣ Client Data JSON:")
const clientData = JSON.parse(Buffer.from(clientDataJSON, 'base64').toString())
console.log(`   Type: ${clientData.type}`)
console.log(`   Origin: ${clientData.origin}`)
console.log(`   Challenge: ${clientData.challenge}`)

// 4. 验证
console.log("\n4️⃣ 开始验证...")

try {
  // 方法1: hash = false (推荐用于 WebAuthn)
  console.log("\n尝试 hash: false")
  const result1 = await WebAuthnP256.verify({
    hash: false,
    metadata: {
      clientDataJSON: clientDataJSON,
      authenticatorData: authenticatorData,
      typeIndex: 1,
      challengeIndex: 23,
      userVerificationRequired: (flags & 0x04) !== 0
    },
    challenge: challenge,
    publicKey: PublicKey.fromHex(publicKeyHex),
    signature: Signature.fromDerHex(signature),
  })
  console.log(`结果: ${result1 ? '✅ 验证成功!' : '❌ 验证失败'}`)
  
  if (!result1) {
    // 方法2: hash = true
    console.log("\n尝试 hash: true")
    const result2 = await WebAuthnP256.verify({
      hash: true,
      metadata: {
        clientDataJSON: clientDataJSON,
        authenticatorData: authenticatorData,
        typeIndex: 1,
        challengeIndex: 23,
        userVerificationRequired: (flags & 0x04) !== 0
      },
      challenge: challenge,
      publicKey: PublicKey.fromHex(publicKeyHex),
      signature: Signature.fromDerHex(signature),
    })
    console.log(`结果: ${result2 ? '✅ 验证成功!' : '❌ 验证失败'}`)
  }
  
} catch (error) {
  console.log(`❌ 错误: ${error.message}`)
}

console.log("\n" + "=" .repeat(50))
console.log("📌 总结:")
if (publicKeyHex.length === 132) { // 0x + 130 chars = 65 bytes
  console.log("✅ 公钥格式正确 (65字节未压缩格式)")
  console.log("⚠️  如果验证仍然失败，可能是:")
  console.log("   1. challenge 不匹配")
  console.log("   2. 签名时使用的公钥与提供的不一致")
  console.log("   3. metadata 索引不正确")
}

// 调试：重建签名数据
console.log("\n🔧 调试信息:")
const clientDataHash = await crypto.subtle.digest('SHA-256', Buffer.from(clientDataJSON, 'base64'))
const clientDataHashHex = Buffer.from(clientDataHash).toString('hex')
console.log(`Client Data Hash: 0x${clientDataHashHex}`)

const signedData = authenticatorData.substring(2) + clientDataHashHex
console.log(`Signed Data: 0x${signedData}`)
console.log(`Signed Data Length: ${signedData.length / 2} bytes`)