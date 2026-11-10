# HTML Paste - URL Generator

Sirf HTML paste karo aur ek share karne layak URL banao.  
**Docker ki zaroorat nahi** — plain Node.js + Express.  
Railway.com (free tier) ya kisi bhi Linux VPS par host karo.

## Deploy kaise karein

### Option A: Railway.com (Free, Docker bina)

1. Repo ko GitHub par push karo.
2. [railway.app](https://railway.app) par login karo → "New Project" → "Deploy from GitHub repo" → ye repo select karo.
3. Railway auto-detect karega ke ye Node.js app hai (`package.json` mein `"start": "node server.js"` hai).
4. Deploy hone ke baad Railway ek URL dega (jaise `https://xxx.up.railway.app`). Wahi apna paste URL banane ke liye kholo.

### Option B: Koi bhi Linux VPS (Ubuntu/Debian) — CLI se

Server par SSH se login karo, phir:

```bash
git clone https://github.com/YOUR_USERNAME/html-paste-url.git
cd html-paste-url
chmod +x deploy.sh
sudo ./deploy.sh
```

Menu milega:

```
1) Install / Update
2) Uninstall
3) Status
0) Exit
```

- **1 Install / Update:** Node.js install karega (agar nahi hai), dependencies install karega, aur `systemd` service banakar background mein chala dega.
- **2 Uninstall:** Service hatakar saaf karega.
- **3 Status:** Batayega ke server chal raha hai ya nahi, aur URL kya hai.

Server default port `3000` par chalta hai. Agar VPS par firewall hai toh port `3000` (ya Railway wala port) open rakhna.

## Folder Structure

```
server.js         # Express backend (no database, file-based storage data/pastes.json)
package.json      # Node.js deps + start script
public/index.html # Frontend: HTML paste karo, URL nikaalo
.env.example      # ENV vars (PORT, BASE_URL)
deploy.sh         # VPS CLI manager (install/update/uninstall/status)
```

## License

MIT