import crypto from 'crypto'

console.log("🔍 WebAuthn 参数详解")
console.log("=" .repeat(60))

// ========================================
// 1. Challenge 的作用和要求
// ========================================
console.log("\n1️⃣ Challenge（挑战值）")
console.log("-".repeat(40))

// 原始消息
const originalMessage = "Test message for Passkey signature"
console.log("原始消息:", originalMessage)

// Challenge 是消息的 SHA256 哈希
const messageBuffer = Buffer.from(originalMessage, 'utf8')
const challengeHash = crypto.createHash('sha256').update(messageBuffer).digest()
const challengeHex = '0x' + challengeHash.toString('hex')
console.log("Challenge (SHA256):", challengeHex)

// WebAuthn 中，challenge 会被 Base64URL 编码后放入 clientDataJSON
const challengeBase64Url = challengeHash.toString('base64url')
console.log("Challenge (Base64URL):", challengeBase64Url)

// ========================================
// 2. ClientDataJSON 的结构
// ========================================
console.log("\n2️⃣ ClientDataJSON 结构")
console.log("-".repeat(40))

// 这是 WebAuthn 创建的标准格式
const clientDataObj = {
  type: "webauthn.get",  // 认证时是 "webauthn.get"，注册时是 "webauthn.create"
  challenge: challengeBase64Url,  // Base64URL 编码的 challenge
  origin: "https://shelchin2025.github.io",  // 必须与 RP ID 匹配
  crossOrigin: false  // 可选
}

const clientDataString = JSON.stringify(clientDataObj)
console.log("ClientDataJSON 对象:", clientDataObj)
console.log("ClientDataJSON 字符串:", clientDataString)

// ClientDataJSON 会被 Base64 编码传输
const clientDataBase64 = Buffer.from(clientDataString).toString('base64')
console.log("ClientDataJSON (Base64):", clientDataBase64)

// ========================================
// 3. 索引的计算
// ========================================
console.log("\n3️⃣ 索引计算")
console.log("-".repeat(40))

// typeIndex: "type" 字段在 JSON 字符串中的位置
const typeIndex = clientDataString.indexOf('"type"')
console.log(`typeIndex: ${typeIndex}`)
console.log(`  含义: "type" 字段从第 ${typeIndex} 个字符开始`)
console.log(`  验证: "${clientDataString.substring(typeIndex, typeIndex + 6)}"`)

// challengeIndex: "challenge" 字段在 JSON 字符串中的位置
const challengeIndex = clientDataString.indexOf('"challenge"')
console.log(`challengeIndex: ${challengeIndex}`)
console.log(`  含义: "challenge" 字段从第 ${challengeIndex} 个字符开始`)
console.log(`  验证: "${clientDataString.substring(challengeIndex, challengeIndex + 11)}"`)

// ========================================
// 4. AuthenticatorData 结构
// ========================================
console.log("\n4️⃣ AuthenticatorData 结构")
console.log("-".repeat(40))

// AuthenticatorData 的二进制结构（37字节最小）
const authenticatorDataHex = "a49150052d03f21b294fe0778b7d4e8a7cd53c92406e021ec9330bfd6d3e56ba1d00000000"
const authData = Buffer.from(authenticatorDataHex, 'hex')

console.log("AuthenticatorData (Hex):", '0x' + authenticatorDataHex)
console.log("长度:", authData.length, "字节")

// 解析结构
console.log("\n结构解析:")
console.log("  [0-31]  RP ID Hash (32字节):", authData.subarray(0, 32).toString('hex'))
console.log("  [32]    Flags (1字节):", '0x' + authData[32].toString(16))

const flags = authData[32]
console.log("          - UP (User Present):", (flags & 0x01) !== 0, "(bit 0)")
console.log("          - UV (User Verified):", (flags & 0x04) !== 0, "(bit 2)")
console.log("          - BE (Backup Eligible):", (flags & 0x08) !== 0, "(bit 3)")
console.log("          - BS (Backup State):", (flags & 0x10) !== 0, "(bit 4)")
console.log("          - AT (Attested Cred):", (flags & 0x40) !== 0, "(bit 6)")
console.log("          - ED (Extension Data):", (flags & 0x80) !== 0, "(bit 7)")

console.log("  [33-36] Counter (4字节):", authData.subarray(33, 37).toString('hex'))

// ========================================
// 5. UserVerificationRequired
// ========================================
console.log("\n5️⃣ UserVerificationRequired")
console.log("-".repeat(40))

const userVerificationRequired = (flags & 0x04) !== 0
console.log("值:", userVerificationRequired)
console.log("含义: 用户是否进行了验证（如 Face ID、Touch ID）")
console.log("来源: AuthenticatorData flags 的第 2 位 (0x04)")

// ========================================
// 6. 签名数据的构造
// ========================================
console.log("\n6️⃣ WebAuthn 签名数据构造")
console.log("-".repeat(40))

// WebAuthn 签名的实际数据
const clientDataHash = crypto.createHash('sha256').update(clientDataString).digest()
console.log("ClientDataJSON Hash:", '0x' + clientDataHash.toString('hex'))

// 签名数据 = authenticatorData || SHA256(clientDataJSON)
const signedData = Buffer.concat([authData, clientDataHash])
console.log("签名数据 = AuthenticatorData + ClientDataHash")
console.log("签名数据长度:", signedData.length, "字节")
console.log("签名数据 (Hex):", '0x' + signedData.toString('hex'))

// ========================================
// 7. 验证条件总结
// ========================================
console.log("\n7️⃣ 验证成功的必要条件")
console.log("-".repeat(40))

console.log("✅ 必须满足的条件:")
console.log("1. challenge 必须匹配:")
console.log("   - iOS 发送的 challenge = SHA256(原始消息)")
console.log("   - clientDataJSON 中的 challenge 必须是同一个值的 Base64URL 编码")

console.log("\n2. 索引必须正确:")
console.log("   - typeIndex: 'type' 在 clientDataJSON 字符串中的位置")
console.log("   - challengeIndex: 'challenge' 在 clientDataJSON 字符串中的位置")

console.log("\n3. 公钥必须匹配:")
console.log("   - 必须是创建 Passkey 时生成的公钥")
console.log("   - 格式: 65字节未压缩格式 (0x04 + X坐标32字节 + Y坐标32字节)")

console.log("\n4. 签名必须有效:")
console.log("   - 使用私钥对 (authenticatorData || SHA256(clientDataJSON)) 签名")
console.log("   - DER 格式的 ECDSA 签名")

console.log("\n5. Origin 必须匹配:")
console.log("   - clientDataJSON 中的 origin 必须与注册时的 RP ID 对应")

// ========================================
// 8. 常见错误
// ========================================
console.log("\n8️⃣ 常见验证失败原因")
console.log("-".repeat(40))

console.log("❌ 公钥不匹配:")
console.log("   - 使用了错误的公钥")
console.log("   - 公钥格式错误（如压缩格式而非未压缩格式）")

console.log("\n❌ Challenge 不匹配:")
console.log("   - iOS 和验证时使用的 challenge 不同")
console.log("   - Base64URL 编码/解码错误")

console.log("\n❌ 索引错误:")
console.log("   - JSON 序列化时的格式不同导致索引偏移")
console.log("   - 空格、换行等影响了索引位置")

console.log("\n❌ Hash 参数错误:")
console.log("   - WebAuthn 通常使用 hash: false")
console.log("   - 因为 challenge 已经是哈希值")

console.log("\n" + "=" .repeat(60))
console.log("💡 调试建议:")
console.log("1. 确保 iOS 保存了正确的公钥")
console.log("2. 检查 challenge 在整个流程中是否一致")
console.log("3. 验证 clientDataJSON 的格式和索引")
console.log("4. 使用 hash: false 进行验证")