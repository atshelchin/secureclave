import crypto from 'crypto'

console.log("🔍 验证你的实际数据")
console.log("=" .repeat(60))

// 你提供的实际数据
const actualData = {
  publicKey: "0x04f7c5d7e5d95011c9d1270e1f01d08334b6343c32a6c09e90d63c077af31aa1ee6a92c9bbf0cf30d142bae019b95130dc534ecaf188de62ab8fb32a9c2973b100",
  challenge: "0x863d37e0f4b8b426788d4d829ad01c830cca5639ddf434bc38d34afde3d673c0",
  authenticatorData: "0xa49150052d03f21b294fe0778b7d4e8a7cd53c92406e021ec9330bfd6d3e56ba1d00000000",
  clientDataJSON_base64: "eyJ0eXBlIjoid2ViYXV0aG4uZ2V0IiwiY2hhbGxlbmdlIjoiaGowMzRQUzR0Q1o0alUyQ210QWNnd3pLVmpuZDlEUzhPTk5LX2VQV2M4QSIsIm9yaWdpbiI6Imh0dHBzOi8vc2hlbGNoaW4yMDI1LmdpdGh1Yi5pbyJ9",
  signature: "0x3045022072157a0e157346183e64c9d24d699ffac7dda22460aee4b20b62b785a6fbe05d022100bcb1c4effe18240ebf179c0f48c55ca0630727dc6a38f14585919e1ed3545d02",
  originalMessage: "Test message for Passkey signature"
}

console.log("原始消息:", actualData.originalMessage)

// ========================================
// 1. 验证 Challenge
// ========================================
console.log("\n1️⃣ Challenge 验证")
console.log("-".repeat(40))

// 计算原始消息的 SHA256
const messageHash = crypto.createHash('sha256')
  .update(Buffer.from(actualData.originalMessage, 'utf8'))
  .digest()
const calculatedChallenge = '0x' + messageHash.toString('hex')

console.log("计算的 Challenge:", calculatedChallenge)
console.log("实际的 Challenge:", actualData.challenge)
console.log("Challenge 匹配:", calculatedChallenge === actualData.challenge ? "✅" : "❌")

// ========================================
// 2. 验证 ClientDataJSON
// ========================================
console.log("\n2️⃣ ClientDataJSON 验证")
console.log("-".repeat(40))

// 解码 clientDataJSON
const clientDataString = Buffer.from(actualData.clientDataJSON_base64, 'base64').toString()
const clientData = JSON.parse(clientDataString)

console.log("ClientDataJSON 内容:", clientData)

// 验证 challenge 在 clientDataJSON 中
const challengeInClientData = Buffer.from(clientData.challenge, 'base64url').toString('hex')
const expectedChallenge = actualData.challenge.substring(2) // 去掉 0x 前缀

console.log("\nChallenge 对比:")
console.log("  ClientData 中:", '0x' + challengeInClientData)
console.log("  预期值:", actualData.challenge)
console.log("  匹配:", challengeInClientData === expectedChallenge ? "✅" : "❌")

// ========================================
// 3. 验证索引
// ========================================
console.log("\n3️⃣ 索引验证")
console.log("-".repeat(40))

const typeIndex = clientDataString.indexOf('"type"')
const challengeIndex = clientDataString.indexOf('"challenge"')

console.log("ClientDataJSON 字符串:", clientDataString)
console.log("\n索引计算:")
console.log("  typeIndex: " + typeIndex)
console.log("  challengeIndex: " + challengeIndex)
console.log("\n验证索引位置:")
console.log(`  在位置 ${typeIndex}: "${clientDataString.substring(typeIndex, typeIndex + 6)}"`)
console.log(`  在位置 ${challengeIndex}: "${clientDataString.substring(challengeIndex, challengeIndex + 11)}"`)

// ========================================
// 4. 验证 AuthenticatorData
// ========================================
console.log("\n4️⃣ AuthenticatorData 验证")
console.log("-".repeat(40))

const authData = Buffer.from(actualData.authenticatorData.substring(2), 'hex')
console.log("长度:", authData.length, "字节", authData.length >= 37 ? "✅" : "❌ (最少需要37字节)")

const flags = authData[32]
console.log("\nFlags: 0x" + flags.toString(16))
console.log("  - User Present (UP):", (flags & 0x01) !== 0)
console.log("  - User Verified (UV):", (flags & 0x04) !== 0)
const userVerificationRequired = (flags & 0x04) !== 0

// ========================================
// 5. 构造签名数据
// ========================================
console.log("\n5️⃣ 签名数据构造")
console.log("-".repeat(40))

// 计算 clientDataJSON 的哈希
const clientDataHash = crypto.createHash('sha256')
  .update(clientDataString)
  .digest()

console.log("ClientDataJSON Hash:", '0x' + clientDataHash.toString('hex'))

// WebAuthn 签名的数据 = authenticatorData || SHA256(clientDataJSON)
const signedData = Buffer.concat([authData, clientDataHash])
console.log("签名数据长度:", signedData.length, "字节")
console.log("签名数据:", '0x' + signedData.toString('hex'))

// ========================================
// 6. 公钥验证
// ========================================
console.log("\n6️⃣ 公钥格式验证")
console.log("-".repeat(40))

const publicKeyBytes = actualData.publicKey.substring(2) // 去掉 0x
console.log("公钥长度:", publicKeyBytes.length / 2, "字节")
console.log("格式前缀:", publicKeyBytes.substring(0, 2))

if (publicKeyBytes.substring(0, 2) === '04') {
  console.log("✅ 未压缩格式 (0x04 开头)")
  console.log("X 坐标:", publicKeyBytes.substring(2, 66))
  console.log("Y 坐标:", publicKeyBytes.substring(66, 130))
} else {
  console.log("❌ 不是未压缩格式")
}

// ========================================
// 7. 总结
// ========================================
console.log("\n7️⃣ 验证参数总结")
console.log("-".repeat(40))

const params = {
  metadata: {
    clientDataJSON: actualData.clientDataJSON_base64,
    authenticatorData: actualData.authenticatorData,
    typeIndex: typeIndex,
    challengeIndex: challengeIndex,
    userVerificationRequired: userVerificationRequired
  },
  challenge: actualData.challenge,
  publicKey: actualData.publicKey,
  signature: actualData.signature,
  hash: false  // WebAuthn 通常使用 false
}

console.log("\n用于 ox 库的完整参数:")
console.log(JSON.stringify(params, null, 2))

console.log("\n" + "=" .repeat(60))
console.log("💡 验证检查清单:")
console.log("✅ Challenge 匹配:", calculatedChallenge === actualData.challenge)
console.log("✅ Challenge 在 ClientData 中正确:", challengeInClientData === expectedChallenge)
console.log("✅ 公钥格式正确:", publicKeyBytes.substring(0, 2) === '04')
console.log("✅ AuthenticatorData 长度正确:", authData.length >= 37)
console.log("✅ User Verification:", userVerificationRequired)

console.log("\n⚠️  如果验证仍然失败，最可能的原因是:")
console.log("1. 签名时使用的私钥与提供的公钥不匹配")
console.log("2. iOS 创建 Passkey 时生成的公钥与签名时使用的不是同一个")
console.log("3. 需要确保 iOS 应用正确保存和使用同一个公钥")