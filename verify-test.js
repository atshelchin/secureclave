import { WebAuthnP256, PublicKey, Signature } from 'ox'

// 你提供的数据
const data = {
  "signature" : "0x3045022072157a0e157346183e64c9d24d699ffac7dda22460aee4b20b62b785a6fbe05d022100bcb1c4effe18240ebf179c0f48c55ca0630727dc6a38f14585919e1ed3545d02",
  "challenge" : "0x863d37e0f4b8b426788d4d829ad01c830cca5639ddf434bc38d34afde3d673c0",
  "authenticatorData_raw" : "0xa49150052d03f21b294fe0778b7d4e8a7cd53c92406e021ec9330bfd6d3e56ba1d00000000",
  "clientDataJSON_raw" : "eyJ0eXBlIjoid2ViYXV0aG4uZ2V0IiwiY2hhbGxlbmdlIjoiaGowMzRQUzR0Q1o0alUyQ210QWNnd3pLVmpuZDlEUzhPTk5LX2VQV2M4QSIsIm9yaWdpbiI6Imh0dHBzOi8vc2hlbGNoaW4yMDI1LmdpdGh1Yi5pbyJ9",
  "metadata" : {
    "userVerificationRequired" : true,
    "clientDataJSON" : "eyJ0eXBlIjoid2ViYXV0aG4uZ2V0IiwiY2hhbGxlbmdlIjoiaGowMzRQUzR0Q1o0alUyQ210QWNnd3pLVmpuZDlEUzhPTk5LX2VQV2c4QSIsIm9yaWdpbiI6Imh0dHBzOi8vc2hlbGNoaW4yMDI1LmdpdGh1Yi5pbyJ9",
    "authenticatorData" : "0xa49150052d03f21b294fe0778b7d4e8a7cd53c92406e021ec9330bfd6d3e56ba1d00000000",
    "challengeIndex" : 23,
    "typeIndex" : 1
  }
}

console.log("❌ 问题: 缺少 publicKey 字段!")
console.log("这说明 iOS 应用没有正确保存或提取公钥")
console.log("")
console.log("需要检查:")
console.log("1. Passkey 创建时是否提取了公钥")
console.log("2. 公钥是否保存到了 SwiftData")
console.log("3. 签名时是否正确读取了保存的公钥")

// 为了测试，我们需要一个公钥
// 从之前的数据看，你的公钥可能是压缩格式
// 让我们尝试使用一个示例公钥

const testPublicKey = "0x04" + // 未压缩格式前缀
  "6e021ec9330bfd6d3e56ba5d00000000fbfc3007154e4ecc8c0b6e020557d7bd" + // X coordinate (32 bytes)
  "1464eca82800b5847991ff101c1349446aeb3ce8b2a5010203262001215820ff"; // Y coordinate (32 bytes) - 这是猜测的

console.log("\n尝试使用构造的测试公钥:")
console.log(testPublicKey)

try {
  const result = await WebAuthnP256.verify({
    hash: false,
    metadata: data.metadata,
    challenge: data.challenge,
    publicKey: PublicKey.fromHex(testPublicKey),
    signature: Signature.fromDerHex(data.signature),
  })
  
  console.log(`验证结果: ${result ? '✅ 成功' : '❌ 失败'}`)
} catch (error) {
  console.log(`错误: ${error.message}`)
}