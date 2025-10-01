#!/bin/bash
exec > /var/log/user-data.log 2>&1

yum update -y

# Install Node.js 18 and nginx
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs git nginx

# Install PM2 globally
npm install -g pm2

# Clone the Reader app
cd /home/ec2-user
git clone https://github.com/Masterpitan/reader.git reader-app
chown -R ec2-user:ec2-user reader-app

# Setup server
cd reader-app/server
sudo -u ec2-user npm install

# Create server environment file
cat > .env << EOL
DATABASE_URL="postgresql://postgres:m5mxhWbB*vJd6_Q@db.jmuoffnxerwetfglxono.supabase.co:5432/postgres"
EOL

# Run database migrations
sudo -u ec2-user npx prisma migrate deploy || echo "Migration failed"
sudo -u ec2-user npx prisma db seed || echo "Seed failed"

# Setup client
cd ../client
sudo -u ec2-user npm install

# Create client environment file
cat > .env.local << EOL
NEXT_PUBLIC_API_URL=http://localhost:3001/
EOL

# Build client for production
sudo -u ec2-user npm run build

# Start server with PM2
cd ../server
sudo -u ec2-user pm2 start npm --name "reader-server" -- run start:dev

# Wait for server to initialize
sleep 20

# Start client with PM2
cd ../client
sudo -u ec2-user pm2 start npm --name "reader-client" -- start

# Configure nginx reverse proxy
cat > /etc/nginx/conf.d/reader.conf << 'EOL'
server {
    listen 80;
    server_name _;

    # API routes
    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Client routes (default)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOL

# Remove default nginx config
rm -f /etc/nginx/conf.d/default.conf

# Test nginx config and start
nginx -t
systemctl enable nginx
systemctl restart nginx

# Save PM2 processes and setup startup
sudo -u ec2-user pm2 save
env PATH=$PATH:/usr/bin pm2 startup systemd -u ec2-user --hp /home/ec2-user

echo "Reader app deployment completed at $(date)" >> /var/log/user-data.log
