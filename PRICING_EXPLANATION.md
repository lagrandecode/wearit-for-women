# Vertex AI Pricing Explained Simply

## Quick Answer: Yes, it's Pay-Per-Use!

Vertex AI charges you **only for what you use** - no monthly subscription required.

---

## How Pricing Works

### 1. Token-Based System
- You pay per **token** (not per request)
- 1 token ≈ 4 characters ≈ 0.75 words
- Example: "Suggest 3 outfits" = ~3 tokens

### 2. Two Types of Tokens
- **Input tokens**: Your prompt/question
- **Output tokens**: AI's response

### 3. Cost Per Token
Different models have different prices:

| Model | Input (per 1M tokens) | Output (per 1M tokens) | Best For |
|-------|----------------------|---------------------|----------|
| Gemini 1.5 Flash | ~$0.075 | ~$0.30 | Most tasks (cheapest) |
| Gemini 1.5 Pro | ~$1.25 | ~$5.00 | Complex tasks |

---

## Real-World Cost Examples

### Example 1: Simple Outfit Recommendation
- **Prompt**: "Suggest 3 casual spring outfits" (10 tokens)
- **Response**: 200 tokens of recommendations
- **Cost with Flash**: 
  - Input: (10 / 1,000,000) × $0.075 = $0.00000075
  - Output: (200 / 1,000,000) × $0.30 = $0.00006
  - **Total: $0.00006** (less than 1 cent!)

### Example 2: 1,000 Requests/Month
- Each request: ~$0.0001 average
- 1,000 requests = **$0.10/month** (10 cents!)

### Example 3: Heavy Usage (10,000 requests/month)
- Average 500 tokens per request
- 10,000 × 500 = 5,000,000 tokens
- Cost: ~$0.50/month (50 cents!)

---

## Free Tier

### What You Get Free:
- **Gemini Flash**: ~1,500 requests/day free
- **Gemini Pro**: ~50 requests/day free
- **No credit card required** to start

### After Free Tier:
- Pay only for tokens used
- No monthly minimum
- No subscription fee

---

## Cost Comparison

| Usage Level | Monthly Cost (Gemini Flash) |
|------------|----------------------------|
| Light (100 requests) | **$0** (free tier) |
| Medium (1,000 requests) | **~$0.10** |
| Heavy (10,000 requests) | **~$1.00** |
| Very Heavy (100,000 requests) | **~$10.00** |

**Note**: These are estimates. Actual costs depend on prompt/response length.

---

## How to Control Costs

### 1. Use Gemini Flash (Cheapest)
```dart
// Use Flash for most tasks
VertexAIService.generateText(
  prompt: 'Your prompt',
  model: VertexAIService.geminiFlash, // Cheapest!
);
```

### 2. Set Budget Alerts
- Go to Google Cloud Console
- Set up billing alerts
- Get notified before spending too much

### 3. Monitor Usage
- Check usage dashboard regularly
- Set daily/monthly quotas
- Review which features use most tokens

### 4. Optimize Prompts
- Shorter prompts = fewer input tokens
- Request concise responses = fewer output tokens
- Cache repeated queries

---

## Billing Details

### When You're Charged:
- **Monthly billing** (end of each month)
- **Only for tokens used** after free tier
- **No upfront cost** or subscription

### Payment:
- Charged to your Google Cloud billing account
- Can set spending limits
- Can pause API access if needed

---

## Is It Worth It?

### For Your Wearit App:

**Typical Usage**:
- User uploads photo → Analyze outfit (1 request)
- Get recommendations → Generate suggestions (1 request)
- Product descriptions → Generate text (1 request)

**Estimated Monthly Cost**:
- 1,000 active users × 10 requests/month = 10,000 requests
- Cost: **~$1-2/month** (very affordable!)

**ROI**:
- Better user experience
- AI-powered features
- Competitive advantage
- **Cost: Less than a coffee per month!**

---

## Summary

✅ **Pay-per-use**: Yes, only pay for tokens used  
✅ **Free tier**: Generous free quota every month  
✅ **Affordable**: Typically $0-5/month for small apps  
✅ **No subscription**: No monthly fees  
✅ **Scalable**: Costs grow with usage  

**Bottom Line**: Start free, pay only for what you use, very affordable for most apps!

---

## Next Steps

1. **Enable Vertex AI API** (free to enable)
2. **Start using free tier** (no cost)
3. **Monitor usage** in Cloud Console
4. **Set budget alerts** if needed
5. **Scale as needed** (costs grow with success!)

---

## Resources

- [Official Pricing](https://cloud.google.com/vertex-ai/pricing)
- [Pricing Calculator](https://cloud.google.com/products/calculator)
- [Usage Dashboard](https://console.cloud.google.com/vertex-ai/usage)
