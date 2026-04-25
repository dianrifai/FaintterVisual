# FaintterVisual — Project README

This repository contains static portfolio pages (HTML/CSS) and asset folders. This README explains how to normalize asset filenames, test locally, and deploy to Vercel safely.

## Why normalize filenames
- Windows is case-insensitive and lenient with spaces/characters; Linux (used by Vercel) is case-sensitive — mismatched file/folder names cause 404 errors after deploy.
- This project includes spaces and parentheses in asset names (e.g. `1. Poster/Poster Semarak Klagaran  (1).png`). The provided script `rename-assets.ps1` helps normalize names and update HTML references.

---

## Files of interest
- `portfolio.html` — main portfolio page (we also added a `vercel.json` to redirect `/` → `/portfolio.html` as a temporary fallback).
- `portfolio.css` — global stylesheet.
- `rename-assets.ps1` — PowerShell script to normalize filenames and update `.html` references.
- `vercel.json` — temporary redirect from `/` to `/portfolio.html`.

---

## Safety & workflow (recommended)
1. Inspect changes first (dry-run):

```powershell
cd "D:\DIAN RIFAI XI DKV 1\codingan dyn\TUGAS"
PowerShell -ExecutionPolicy Bypass -File .\rename-assets.ps1
```

- This runs in DRY-RUN mode and will show folder/file rename mappings and which HTML files would be updated.
- No files are changed in dry-run mode.

2. If the proposed renames look correct, run for real:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\rename-assets.ps1 -Execute
```

- The script will rename directories/files and update `.html` references.
- It backs up any modified `.html` files with a `.bak` extension.
- The script prints each rename performed.

3. Check the site locally before committing:

```powershell
# from project root
python -m http.server 8080
# then open http://localhost:8080/portfolio.html (or / if you created index.html)
```

- Confirm thumbnails open in the lightbox and video files play.

4. Commit & push changes to GitHub:

```powershell
git add .
git commit -m "Normalize asset names; update HTML paths; add vercel.json redirect"
git push origin main
```

5. Vercel will auto-deploy after push (if connected). If not, trigger a redeploy on the Vercel dashboard.

---

## If you prefer NOT to rename now
- We added `vercel.json` that redirects `/` → `/portfolio.html` so visitors land on your portfolio page. This is a temporary fallback — normalizing filenames is recommended.

---

## Troubleshooting
- 404 on a specific asset: inspect the path in the browser DevTools (Network tab) and compare to the actual path/name in your repository (case and spaces must match exactly).
- If any HTML page looks wrong after rename, restore the `.bak` copy and re-check the rename mapping.
- To revert renames manually: use your version control (commit history) or restore backups if you ran the script.

---

## Notes
- The script removes parentheses and replaces spaces with `-`, and strips unusual characters. Review the dry-run carefully to ensure no undesired names.
- If you want me to perform additional automated updates (create `index.html`, or mass-edit captions), tell me which option you prefer.

---

If you want, I can also produce a small checklist for Vercel settings to make sure branch and root are correct. Want that? (yes/no)
