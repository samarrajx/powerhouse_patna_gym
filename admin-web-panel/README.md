# React + Vite

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Oxc](https://oxc.rs)
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/)

## React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the ESLint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and [`typescript-eslint`](https://typescript-eslint.io) in your project.

## 🔑 Environment Variables — Handover Checklist

All secrets are stored as Vercel environment variables. Before going live, ensure the following are set in **both** the backend and web panel Vercel projects:

### Backend (`/backend`)
| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key (not the anon key) |
| `JWT_SECRET` | A long random string used to sign auth tokens |
| `DATABASE_URL` | Full Supabase PostgreSQL connection string |
| `FIREBASE_SERVICE_ACCOUNT` | Full Firebase service account JSON (stringified) |

### How to set secrets on Vercel
1. Go to your Vercel project → **Settings** → **Environment Variables**
2. Add each variable above for the **Production** environment
3. Redeploy for changes to take effect

> ⚠️ Never commit `.env` files or service account JSON to the repository.
