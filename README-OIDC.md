### **How to Get GitHub's OIDC Thumbprint for AWS**

The thumbprint is a **SHA-1 hash** of GitHub's OIDC provider TLS certificate. You can obtain it in two ways:

---

## **Option 1: Automatically Fetch with OpenSSL (Recommended)**
Run this command to get the latest thumbprint (Linux/macOS/WSL):
```bash
openssl s_client -servername token.actions.githubusercontent.com -connect token.actions.githubusercontent.com:443 < /dev/null 2>/dev/null \
  | openssl x509 -fingerprint -noout \
  | cut -d '=' -f 2 \
  | tr -d ':' \
  | tr '[:upper:]' '[:lower:]'
```
**Output Example:**
```
74f3a68f16524f15424927704c9506f55a9316bd

```
→ This should match the thumbprint in the Terraform example.

---

## **Option 2: Manually Verify via Browser**
1. **Visit GitHub's OIDC URL** in a browser:  
   🔗 [https://token.actions.githubusercontent.com/.well-known/openid-configuration](https://token.actions.githubusercontent.com/.well-known/openid-configuration)
2. **Check the TLS Certificate**:
   - Chrome: Click the **🔒 padlock** → **Certificate** → **Details** → **Thumbprint (SHA-1)**.
   - Firefox: Click the **🔒 padlock** → **Connection Secure** → **More Information** → **View Certificate** → **SHA-1 Fingerprint**.

---

## **Why This Thumbprint is Needed**
- AWS uses it to **verify GitHub's identity** when GitHub Actions requests temporary credentials.
- It prevents impersonation attacks ("man-in-the-middle").
- The thumbprint rarely changes, but if it does, AWS will reject OIDC connections until updated.

---

## **Important Notes**
1. **Use the exact thumbprint** (lowercase, no colons):  
   ```hcl
   thumbprint_list = ["74f3a68f16524f15424927704c9506f55a9316bd"]  # Correct
   thumbprint_list = ["69:38:fd:..."]                              # ❌ Incorrect (colons)
   ```
2. **If GitHub changes it**, you’ll see AWS errors like:  
   `"InvalidIdentityToken: OpenID Connect provider's HTTPS certificate doesn't match configured thumbprint"`  
   → Re-run the `openssl` command to fetch the new one.

3. **No need to hardcode** if using Terraform `aws_iam_openid_connect_provider` with `thumbprint_list`—it’s already correct in the example.

---

#################### SETTING UP OIDC github ################################################
# ## **oidc-provider.tf (Account-Level Setup (Run once manually outside of main.tf))**
#```hcl
# resource "aws_iam_openid_connect_provider" "github" {
#  url             = "https://token.actions.githubusercontent.com"
#  client_id_list  = ["sts.amazonaws.com"]
#  thumbprint_list = ["74f3a68f16524f15424927704c9506f55a9316bd"]  # From above
# }
# ```
#############################################################################################
Let me know if you run into issues! This is a one-time setup. 🚀