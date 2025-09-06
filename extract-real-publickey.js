// 分析提供的"公钥"数据
const publicKeyHex = "04a5010203262001215820303f1bb19daf5d5292d5fbf401f142f09f9c1a62cc1cd97e0a4a61daa0e4db0c2258203a2e2679dfd4d274448b201f4113f46929c4fc"

console.log("分析公钥数据")
console.log("=" .repeat(50))

const data = Buffer.from(publicKeyHex, 'hex')
console.log("总长度:", data.length, "bytes")
console.log("Hex:", publicKeyHex)
console.log("")

// 这看起来像是部分 COSE 编码
// 0x04 是我们添加的前缀
// a5 01 02 03 26 20 01 是 COSE map 的开始
// 21 58 20 = label -2 (x coordinate), byte string of 32
// 22 58 20 = label -3 (y coordinate), byte string of 32

console.log("解析 COSE 结构:")
console.log("  0x04 - 我们添加的前缀")
console.log("  0xa5 - COSE map with 5 items")
console.log("")

// 找 X 坐标 (0x21 0x58 0x20)
let xStart = -1
for (let i = 1; i < data.length - 34; i++) {
  if (data[i] === 0x21 && data[i+1] === 0x58 && data[i+2] === 0x20) {
    xStart = i + 3
    console.log("找到 X 坐标 at offset", i)
    break
  }
}

// 找 Y 坐标 (0x22 0x58 0x20)  
let yStart = -1
for (let i = 1; i < data.length - 34; i++) {
  if (data[i] === 0x22 && data[i+1] === 0x58 && data[i+2] === 0x20) {
    yStart = i + 3
    console.log("找到 Y 坐标 at offset", i)
    break
  }
}

if (xStart > 0) {
  const x = data.slice(xStart, xStart + 32)
  console.log("\nX 坐标 (32 bytes):")
  console.log("  ", x.toString('hex'))
}

if (yStart > 0) {
  const y = data.slice(yStart, yStart + 32)
  console.log("\nY 坐标 (32 bytes):")
  console.log("  ", y.toString('hex'))
} else {
  // Y 坐标可能被截断了
  console.log("\n⚠️ Y 坐标似乎被截断或丢失")
  console.log("数据末尾:", data.slice(-10).toString('hex'))
  
  // 检查数据结尾是否有部分 Y 坐标
  const remaining = data.slice(xStart + 32)
  console.log("\nX 坐标后的剩余数据 (" + remaining.length + " bytes):")
  console.log("  ", remaining.toString('hex'))
  
  if (remaining.length >= 35 && remaining[0] === 0x22 && remaining[1] === 0x58 && remaining[2] === 0x20) {
    const y = remaining.slice(3, 35)
    console.log("\n找到完整 Y 坐标:")
    console.log("  ", y.toString('hex'))
    
    // 构建正确的公钥
    const correctPublicKey = Buffer.concat([Buffer.from([0x04]), data.slice(xStart, xStart + 32), y])
    console.log("\n✅ 重构的正确公钥 (65 bytes):")
    console.log("0x" + correctPublicKey.toString('hex'))
  } else {
    console.log("\n❌ Y 坐标数据不完整，只有", remaining.length - 3, "字节")
    console.log("需要 32 字节，但数据被截断了")
  }
}