# 📝 EC256/P-256 签名格式说明

## 🔑 签名长度说明

### X9.62 格式（DER 编码）- iOS 默认格式
- **长度**: 约 70-72 字节（140-144 个十六进制字符）
- **格式**: DER 编码的 ASN.1 结构
- **结构**: 
  ```
  30 [总长度] 
    02 [r长度] [r值] 
    02 [s长度] [s值]
  ```
- **特点**: 长度可变（因为 DER 编码会去除前导零）

### 原始格式（Raw）
- **长度**: 恰好 64 字节（128 个十六进制字符）
- **格式**: r || s （连接）
- **结构**: 32 字节 r + 32 字节 s
- **特点**: 固定长度

## ❓ 为什么是 140 个字符？

iOS 的 `SecKeyCreateSignature` 使用 `.ecdsaSignatureMessageX962SHA256` 会产生 **X9.62 格式（DER 编码）** 的签名：

1. **DER 编码开销**: 约 6-8 字节
2. **实际签名数据**: 64 字节（r + s）
3. **总计**: 约 70-72 字节 = 140-144 个十六进制字符

## ✅ 这是正确的！

**140 个字符的签名是正常的**，因为：
- iOS 使用 DER 编码格式
- 包含了 ASN.1 结构信息
- 这是标准的 X9.62 格式

## 🔄 格式转换

### DER 到 Raw（如果需要）
```swift
func derToRaw(_ derSignature: Data) -> Data? {
    // DER 格式: 30 [len] 02 [r_len] [r] 02 [s_len] [s]
    guard derSignature.count >= 8,
          derSignature[0] == 0x30 else { return nil }
    
    var offset = 2
    
    // 读取 r
    guard derSignature[offset] == 0x02 else { return nil }
    offset += 1
    let rLength = Int(derSignature[offset])
    offset += 1
    let r = derSignature.subdata(in: offset..<offset+rLength)
    offset += rLength
    
    // 读取 s
    guard derSignature[offset] == 0x02 else { return nil }
    offset += 1
    let sLength = Int(derSignature[offset])
    offset += 1
    let s = derSignature.subdata(in: offset..<offset+sLength)
    
    // 填充到 32 字节
    var rawSignature = Data()
    rawSignature.append(Data(repeating: 0, count: max(0, 32 - r.count)))
    rawSignature.append(r.suffix(32))
    rawSignature.append(Data(repeating: 0, count: max(0, 32 - s.count)))
    rawSignature.append(s.suffix(32))
    
    return rawSignature
}
```

## 🔍 验证签名

### 使用相同格式验证
```swift
// 签名和验证必须使用相同的算法
SecKeyCreateSignature(
    privateKey,
    .ecdsaSignatureMessageX962SHA256,  // X9.62 格式
    data,
    &error
)

SecKeyVerifySignature(
    publicKey,
    .ecdsaSignatureMessageX962SHA256,  // 必须相同
    data,
    signature,
    &error
)
```

## 📊 签名示例

### X9.62 格式（iOS 产生的）
```
304502206e7a8b4c... (140-144 字符)
```

### 原始格式（某些系统需要）
```
6e7a8b4c3d2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c... (128 字符)
```

## ⚠️ 注意事项

1. **iOS 默认使用 X9.62 格式** - 这是正确和标准的
2. **140 个字符是正常的** - 不是错误
3. **验证时必须使用相同格式** - 不要混用格式
4. **与其他系统交互** - 可能需要格式转换

## 🛠 故障排除

| 问题 | 原因 | 解决 |
|-----|------|------|
| "Invalid signature size" | 期望原始格式但收到 DER | 转换格式或调整验证方法 |
| 签名 140 字符 | 正常的 X9.62 格式 | 这是正确的 |
| 验证失败 | 格式不匹配 | 确保签名和验证使用相同算法 |