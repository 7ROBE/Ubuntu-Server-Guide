
# Ubuntu Server Complete Setup Guide

Welcome to the ultimate guide for setting up an Ubuntu Server! This step-by-step manual will help you install, configure, and secure your server, making sure it's ready for production or personal use. Whether you're a beginner or experienced, follow along to get your server up and running smoothly.

## Overview

This guide will walk you through the following:

- Installing and configuring OpenSSH for remote access
- Setting a static IP address
- Installing essential software for server security and performance
- Best practices for server management and regular maintenance

Let's get started!

## Step 1: Update System

Before starting, make sure the system is up to date.

```bash
sudo apt update && sudo apt upgrade -y
```

## Step 2: Install OpenSSH

OpenSSH allows you to remotely access your server. To install it, run:

```bash
sudo apt install openssh-server -y
```

Once installed, check the status to ensure the service is running:

```bash
sudo systemctl status ssh
```

If not running, start and enable the service to launch on boot:

```bash
sudo systemctl start ssh
sudo systemctl enable ssh
```

## Step 3: Configure Static IP Address

To ensure your server always uses the same IP address, you’ll need to set a static IP.

1. **Identify the Network Interface:**
   Use the following command to list network interfaces:

   ```bash
   ip a
   ```

   Identify your main interface (e.g., `eth0` or `ens160`).

2. **Modify the Netplan Configuration:**
   Open the Netplan configuration file:

   ```bash
   sudo nano /etc/netplan/00-installer-config.yaml
   ```

   Update it with your network information:

   ```yaml
   network:
     version: 2
     ethernets:
       <interface_name>:
         dhcp4: no
         addresses:
           - <your_static_ip>/24
         gateway4: <your_gateway>
         nameservers:
           addresses:
             - <your_dns_server>
   ```

   Replace `<interface_name>`, `<your_static_ip>`, `<your_gateway>`, and `<your_dns_server>` with your specific values.

3. **Apply the Configuration:**

   ```bash
   sudo netplan apply
   ```

4. **Test the Connection:**
   Verify the server's connection by pinging an external address:

   ```bash
   ping 8.8.8.8
   ```

## Step 4: Access Your Server Remotely

You can now access your server from another machine using SSH:

```bash
ssh <your_username>@<your_server_ip>
```

## Step 5: Install Recommended Software

Below are some useful software tools for managing and optimizing your server.

### 1. **Fail2Ban**

Fail2Ban monitors logs and bans IPs that show malicious signs, such as repeated failed login attempts.

```bash
sudo apt install fail2ban -y
```

You can adjust its settings in `/etc/fail2ban/jail.conf` to suit your security needs.

### 2. **UFW (Uncomplicated Firewall)**

UFW is an easy-to-use firewall tool to manage access to your server.

```bash
sudo apt install ufw -y
sudo ufw allow OpenSSH
sudo ufw enable
```

### 3. **Docker**

Docker allows you to run applications in isolated containers, which is great for deploying and testing software environments.

```bash
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
```

### 4. **htop**

htop is an interactive system monitor that provides a detailed view of system processes and resource usage.

```bash
sudo apt install htop -y
```

### 5. **net-tools**

The `net-tools` package includes networking utilities like `ifconfig`, useful for debugging network issues.

```bash
sudo apt install net-tools -y
```

### 6. **Apache or Nginx (Web Server)**

You can install either Apache or Nginx, depending on your preference.

- **Apache:**

  ```bash
  sudo apt install apache2 -y
  ```

- **Nginx:**

  ```bash
  sudo apt install nginx -y
  ```

### 7. **Database Server (MySQL or PostgreSQL)**

Install a database server based on your application needs.

- **MySQL:**

  ```bash
  sudo apt install mysql-server -y
  ```

- **PostgreSQL:**

  ```bash
  sudo apt install postgresql postgresql-contrib -y
  ```

### 8. **certbot (SSL Certificates)**

certbot allows you to easily manage SSL certificates from Let’s Encrypt.

For Nginx:

```bash
sudo apt install certbot python3-certbot-nginx -y
```

For Apache:

```bash
sudo apt install certbot python3-certbot-apache -y
```

## Step 6: Server Management and Maintenance

### Monitoring Server Logs

Keep track of server logs using `journalctl`:

```bash
sudo journalctl -xe
```

### Regular Updates

To keep your server secure and up to date, periodically run:

```bash
sudo apt update && sudo apt upgrade -y
```

You can also enable automatic security updates:

```bash
sudo apt install unattended-upgrades -y
```

Edit the config file:

```bash
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

## Recommendations and Best Practices

To keep your server running smoothly, follow these best practices:

1. **Regular Backups**: Always perform regular backups of critical data using tools like `rsync` or backup services.
2. **Security Hardening**: Use tools like Fail2Ban, and consider setting up SSH keys for more secure authentication. 
3. **Monitor Performance**: Utilize `htop` or other monitoring tools to ensure your server is performing well under load.
4. **Use Docker for Deployment**: Docker containers can isolate applications, making deployments cleaner and easier to manage.
5. **Test on a Local Server First**: If possible, deploy new services and applications on a test server before moving to production.

## Conclusion

Your Ubuntu Server is now set up with OpenSSH for remote access, a static IP address for consistent networking, and several recommended tools for improving security, performance, and management. Follow the best practices to maintain your server’s health and security over time. Keep your system updated, monitor performance, and secure access to prevent unauthorized activities.

With this setup, you're ready to run a stable and secure server environment. Enjoy your newly configured Ubuntu Server!
