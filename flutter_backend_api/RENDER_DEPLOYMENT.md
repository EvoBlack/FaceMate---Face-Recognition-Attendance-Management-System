# Deploy to Render.com - Guide

## Quick Deploy

### Step 1: Push Updated Code
```bash
cd flutter_backend_api
git add .
git commit -m "Fix: Update dependencies for Python 3.11 compatibility"
git push origin main
```

### Step 2: Deploy on Render

1. Go to https://render.com
2. Sign in with GitHub
3. Click "New +" → "Web Service"
4. Connect your repository: `EvoBlack/FaceMate-Backend`
5. Render will auto-detect the `render.yaml` configuration

## Configuration

### Environment Variables (Set in Render Dashboard)

**Required:**
```
DB_HOST=your-mysql-host
DB_USER=your-mysql-user
DB_PASSWORD=your-mysql-password
DB_NAME=face_recognizer
```

**Optional:**
```
FLASK_ENV=production
FLASK_DEBUG=0
SECRET_KEY=auto-generated-by-render
```

### Database Setup

**Option 1: Use Render PostgreSQL (Recommended)**
1. Create a PostgreSQL database on Render
2. Update `app.py` to use PostgreSQL instead of MySQL
3. Update requirements: `psycopg2-binary` instead of `mysql-connector-python`

**Option 2: External MySQL**
1. Use a MySQL service (AWS RDS, PlanetScale, etc.)
2. Add connection details to environment variables
3. Ensure database is accessible from Render IPs

**Option 3: Render MySQL (via Docker)**
1. Not directly supported
2. Use external MySQL service

## Files Added for Render

### 1. `runtime.txt`
```
python-3.11.9
```
Specifies Python version compatible with all dependencies.

### 2. `render.yaml`
```yaml
services:
  - type: web
    name: facemate-backend
    env: python
    runtime: python-3.11.9
    buildCommand: pip install -r requirements.txt
    startCommand: gunicorn -w 2 -b 0.0.0.0:$PORT --timeout 120 app:app
```

### 3. Updated `requirements.txt`
- Changed `opencv-python` → `opencv-python-headless` (no GUI needed)
- Updated `torch` 2.1.0 → 2.5.1 (Python 3.11+ support)
- Updated `torchvision` 0.16.0 → 0.20.1
- Updated `facenet-pytorch` 2.5.3 → 2.6.0

## Deployment Steps

### 1. Initial Setup
```bash
# In flutter_backend_api folder
git add runtime.txt render.yaml requirements.txt
git commit -m "Add Render deployment configuration"
git push origin main
```

### 2. Create Web Service on Render
1. Dashboard → New → Web Service
2. Connect GitHub repository
3. Select `EvoBlack/FaceMate-Backend`
4. Render auto-detects settings from `render.yaml`
5. Click "Create Web Service"

### 3. Configure Environment Variables
In Render Dashboard → Environment:
```
DB_HOST=your-database-host
DB_USER=your-database-user
DB_PASSWORD=your-database-password
DB_NAME=face_recognizer
```

### 4. Deploy
- Render automatically deploys on push to main
- Or click "Manual Deploy" → "Deploy latest commit"

## Database Migration

### Initialize Database on First Deploy

**Option A: Using Render Shell**
```bash
# In Render Dashboard → Shell
python init_database.py
```

**Option B: Using Local Connection**
```bash
# Connect to Render database from local machine
python init_database.py
```

## Troubleshooting

### Build Fails: Python Version
**Error:** `torch==2.1.0` not found for Python 3.13

**Fix:** Ensure `runtime.txt` exists with `python-3.11.9`

### Build Fails: OpenCV
**Error:** OpenCV GUI dependencies missing

**Fix:** Use `opencv-python-headless` instead of `opencv-python`

### Database Connection Failed
**Error:** Can't connect to MySQL

**Fix:**
1. Check environment variables are set
2. Verify database host is accessible
3. Check firewall rules
4. Use connection string format: `host:port`

### Out of Memory
**Error:** Worker killed (OOM)

**Fix:**
1. Upgrade Render plan (more RAM)
2. Reduce Gunicorn workers: `-w 1`
3. Optimize face recognition model loading

### Timeout During Build
**Error:** Build timeout (numpy compilation)

**Fix:** Already handled - numpy 1.26.4 has pre-built wheels

## Performance Optimization

### 1. Reduce Workers
```yaml
startCommand: gunicorn -w 1 -b 0.0.0.0:$PORT --timeout 120 app:app
```
Face recognition is CPU-intensive, fewer workers = more stable

### 2. Increase Timeout
```yaml
startCommand: gunicorn -w 2 -b 0.0.0.0:$PORT --timeout 300 app:app
```
Face recognition can take time

### 3. Use CPU-Only PyTorch
Already configured - no CUDA dependencies

## Monitoring

### Health Check
```bash
curl https://your-app.onrender.com/api/health
```

### Logs
- Render Dashboard → Logs
- Real-time log streaming
- Download logs for analysis

## Scaling

### Free Tier Limitations
- Spins down after 15 minutes of inactivity
- 750 hours/month free
- Shared CPU
- 512 MB RAM

### Paid Tier Benefits
- Always on
- More RAM (1GB, 2GB, 4GB+)
- Dedicated CPU
- Better performance

## Cost Estimate

### Free Tier
- $0/month
- Good for testing
- Spins down when inactive

### Starter ($7/month)
- 512 MB RAM
- Always on
- Good for small deployments

### Standard ($25/month)
- 2 GB RAM
- Better for face recognition
- Recommended for production

## Alternative: Docker Deployment

If Render doesn't work, use Docker:

```bash
# Build
docker build -t facemate-backend .

# Run
docker run -p 5000:5000 \
  -e DB_HOST=your-host \
  -e DB_USER=your-user \
  -e DB_PASSWORD=your-password \
  -e DB_NAME=face_recognizer \
  facemate-backend
```

Deploy Docker image to:
- AWS ECS
- Google Cloud Run
- Azure Container Instances
- DigitalOcean App Platform

## Support

### Render Documentation
- https://render.com/docs/deploy-flask
- https://render.com/docs/python-version

### Common Issues
1. **Build fails:** Check `runtime.txt` and `requirements.txt`
2. **App crashes:** Check logs for errors
3. **Slow response:** Upgrade plan or reduce workers
4. **Database errors:** Verify connection details

## Success Checklist

- [ ] `runtime.txt` created (python-3.11.9)
- [ ] `render.yaml` created
- [ ] `requirements.txt` updated (opencv-headless, torch 2.5.1)
- [ ] Code pushed to GitHub
- [ ] Render service created
- [ ] Environment variables configured
- [ ] Database initialized
- [ ] Health check passes
- [ ] Face recognition tested

Your backend should now be live at:
`https://your-app-name.onrender.com`
