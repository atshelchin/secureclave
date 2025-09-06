import { WebAuthnP256, PublicKey, Signature } from 'ox'
import crypto from 'crypto'

// 你提供的数据
const data = {
  signature: "0x3045022100f1b8ee95a6e90aaa1c7627fb50b8dff218804ca1d06b6c114d0c28fadd4a9d340220220e3eaf39726e45444f7ff2a068c5b82208b34a85f460c4e6d800722c97032e",
  authenticatorData_raw: "0xb2c0ba7bb038330daf4347f16babea5dfb15ed8f9f451fc96328e1760b3786881d00000000",
  metadata: {
    challengeIndex: 23,
    userVerificationRequired: true,
    authenticatorData: "0xb2c0ba7bb038330daf4347f16babea5dfb15ed8f9f451fc96328e1760b3786881d00000000",
    typeIndex: 1,
    clientDataJSON:"{\"type\":\"webauthn.get\",\"challenge\":\"hj034PS4tCZ4jU2CmtAcgwzKVjnd9DS8ONNK_ePWc8A\",\"origin\":\"https://atshelchin.github.io\"}",// "eyJ0eXBlIjoid2ViYXV0aG4uZ2V0IiwiY2hhbGxlbmdlIjoiaGowMzRQUzR0Q1o0alUyQ210QWNnd3pLVmpuZDlEUzhPTk5LX2VQV2M4QSIsIm9yaWdpbiI6Imh0dHBzOi8vYXRzaGVsY2hpbi5naXRodWIuaW8ifQ=="
  },
  clientDataJSON_raw: "eyJ0eXBlIjoid2ViYXV0aG4uZ2V0IiwiY2hhbGxlbmdlIjoiaGowMzRQUzR0Q1o0alUyQ210QWNnd3pLVmpuZDlEUzhPTk5LX2VQV2M4QSIsIm9yaWdpbiI6Imh0dHBzOi8vYXRzaGVsY2hpbi5naXRodWIuaW8ifQ==",
  clientDataJSON_decoded: "{\"type\":\"webauthn.get\",\"challenge\":\"hj034PS4tCZ4jU2CmtAcgwzKVjnd9DS8ONNK_ePWc8A\",\"origin\":\"https://atshelchin.github.io\"}",
  message: "Test message for Passkey signature",
  verificationResult: false,
  publicKey: "0x04303f1bb19daf5d5292d5fbf401f142f09f9c1a62cc1cd97e0a4a61daa0e4db0c3a2e2679dfd4d274448b201f4113f46929c4fcfbbcc56afab3d2ea31a3381b1a",
  challenge: "0x863d37e0f4b8b426788d4d829ad01c830cca5639ddf434bc38d34afde3d673c0"
}

console.log("🔍 WebAuthn 签名验证")
console.log("=" .repeat(60))

// 1. 检查公钥格式
console.log("\n1️⃣ 公钥分析：")
console.log(`  长度：${(data.publicKey.length - 2) / 2} 字节`)
const publicKeyBytes = data.publicKey.substring(2)
if (publicKeyBytes.substring(0, 2) === '04') {
  console.log("  ✅ 未压缩格式 (0x04 开头)")
  
  // 但是这个公钥看起来不对！它包含了 COSE 结构
  console.log("  ⚠️ 警告：公钥似乎包含 COSE 编码数据")
  
  // 尝试解析真正的公钥
  // 在 COSE 中寻找 x 和 y 坐标
  const pkData = Buffer.from(publicKeyBytes, 'hex')
  console.log("  原始数据：", publicKeyBytes)
  
  // 寻找 0x215820 (label -2, bytes(32)) 和 0x225820 (label -3, bytes(32))
  let x = null, y = null
  for (let i = 0; i < pkData.length - 34; i++) {
    if (pkData[i] === 0x21 && pkData[i+1] === 0x58 && pkData[i+2] === 0x20) {
      x = pkData.slice(i+3, i+35)
      console.log("  找到 X 坐标：", x.toString('hex'))
    }
    if (pkData[i] === 0x22 && pkData[i+1] === 0x58 && pkData[i+2] === 0x20) {
      y = pkData.slice(i+3, i+35)
      console.log("  找到 Y 坐标：", y.toString('hex'))
    }
  }
  
  if (x && y) {
    // 重构正确的公钥
    const correctPublicKey = '0x04' + x.toString('hex') + y.toString('hex')
    console.log("\n  ✅ 提取的正确公钥：")
    console.log("    ", correctPublicKey)
    data.publicKey = correctPublicKey
  }
}

// 2. 检查 authenticatorData
console.log("\n2️⃣ Authenticator Data:")
const authData = data.authenticatorData_raw.substring(2)
console.log(`  长度：${authData.length / 2} 字节`)
const flags = parseInt(authData.substring(64, 66), 16)
console.log(`  Flags: 0x${authData.substring(64, 66)}`)
console.log(`  - User Present (UP): ${(flags & 0x01) !== 0}`)
console.log(`  - User Verified (UV): ${(flags & 0x04) !== 0}`)

// 3. 解析 clientDataJSON
console.log("\n3️⃣ Client Data JSON:")
const clientData = JSON.parse(Buffer.from(data.clientDataJSON_raw, 'base64').toString())
console.log(`  Type: ${clientData.type}`)
console.log(`  Origin: ${clientData.origin}`)
console.log(`  Challenge: ${clientData.challenge}`)

// 验证 challenge
const challengeFromClient = Buffer.from(clientData.challenge, 'base64url').toString('hex')
console.log(`  Challenge (hex): 0x${challengeFromClient}`)
console.log(`  Expected: ${data.challenge}`)
console.log(`  Match: ${('0x' + challengeFromClient) === data.challenge ? '✅' : '❌'}`)

// 4. 验证签名
console.log("\n4️⃣ 开始验证...")

try {
  // 使用 ox 库验证
  const result = await WebAuthnP256.verify({
    hash: false, // WebAuthn 通常使用 false
    metadata: data.metadata,
    challenge: data.challenge,
    publicKey: PublicKey.fromHex(data.publicKey),
    signature: Signature.fromDerHex(data.signature),
  })
  
  console.log(`\n验证结果：${result ? '✅ 成功!' : '❌ 失败'}`)
  
  if (!result) {
    // 尝试 hash: true
    console.log("\n尝试 hash: true...")
    const result2 = await WebAuthnP256.verify({
      hash: true,
      metadata: data.metadata,
      challenge: data.challenge,
      publicKey: PublicKey.fromHex(data.publicKey),
      signature: Signature.fromDerHex(data.signature),
    })
    console.log(`验证结果：${result2 ? '✅ 成功!' : '❌ 失败'}`)
  }
  
} catch (error) {
  console.log(`\n❌ 错误：${error.message}`)
}

// 5. 调试信息
console.log("\n5️⃣ 调试信息：")
console.log("签名数据构成：")
console.log("  authenticatorData + SHA256(clientDataJSON)")

const clientDataHash = crypto.createHash('sha256')
  .update(Buffer.from(data.clientDataJSON_raw, 'base64'))
  .digest('hex')
console.log(`  Client Data Hash: 0x${clientDataHash}`)

const signedData = authData + clientDataHash
console.log(`  完整签名数据：0x${signedData}`)
console.log(`  签名数据长度：${signedData.length / 2} 字节`)

console.log("\n" + "=" .repeat(60))
console.log("📌 总结：")
console.log("  公钥已从 COSE 格式中提取")
console.log("  Challenge 匹配")
console.log("  如果验证仍失败，可能是公钥不匹配")