#!/bin/sh

_step_counter=0
step() {
	_step_counter=$(( _step_counter + 1 ))
	printf '\n\033[1;36m%d) %s\033[0m\n' $_step_counter "$@" >&2  # bold cyan
}


step 'Set up timezone'
setup-timezone -z Europe/Helsinki

step 'Set up networking'
cat > /etc/network/interfaces <<-EOF
	iface lo inet loopback
	iface eth0 inet dhcp
EOF
ln -s networking /etc/init.d/net.lo
ln -s networking /etc/init.d/net.eth0

step 'Adjust rc.conf'
sed -Ei \
	-e 's/^[# ](rc_depend_strict)=.*/\1=NO/' \
	-e 's/^[# ](rc_logger)=.*/\1=YES/' \
	-e 's/^[# ](unicode)=.*/\1=YES/' \
	/etc/rc.conf

step 'Enable services'
rc-update add acpid default
rc-update add net.eth0 default
rc-update add net.lo boot
rc-update add termencoding boot

step 'Add Traefik user'
addgroup -g 3000 traefik
adduser -u 1000 -G traefik -D -h /home/traefik -s /bin/sh traefik
echo 'net.ipv4.ip_unprivileged_port_start=0' > /etc/sysctl.d/50-unprivileged-ports.conf

step 'Include Traefik'
mkdir /traefik
mkdir /traefik/bin
mkdir /traefik/conf.d
wget -O /tmp/traefik.tar.gz https://github.com/traefik/traefik/releases/download/v2.5.3/traefik_v2.5.3_linux_amd64.tar.gz
cd /traefik/bin
tar -zxvf /tmp/traefik.tar.gz
rm /tmp/traefik.tar.gz
chmod 0755 /traefik/bin
cat > /traefik/traefik.yml <<-EOF
accessLog: {}
ping: {}
api:
  dashboard: true
  insecure: true
pilot:
  dashboard: false
providers:
  file:
    directory: /conf.d
    watch: false
entryPoints:
  web:
    address: :80
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: :443
EOF

cat > /traefik/conf.d/00_tls.yml <<-EOF
tls:
  options:
    default:
      minVersion: VersionTLS12
      cipherSuites:
        - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
        - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
        - TLS_AES_128_GCM_SHA256
        - TLS_AES_256_GCM_SHA384
        - TLS_CHACHA20_POLY1305_SHA256
      curvePreferences:
        - CurveP521
        - CurveP384
      sniStrict: true
EOF
cat > /traefik/conf.d/01_secHeaders.yml <<-EOF
http:
  middlewares:
    secHeaders:
      headers:
        browserXssFilter: true
        contentTypeNosniff: true
        frameDeny: true
        sslRedirect: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 15768000
EOF

step 'Traefik example apps'
cat > /traefik/conf.d/foo.yml <<-EOF
http:
  services:
    foo:
      loadBalancer:
        servers:
        - url: "https://server1/"
  routers:
    foo:
      entryPoints:
      - "websecure"
      rule: "Host(\`foo.com\`)"
      middlewares: secHeaders@file
      service: "foo"
EOF

cat > /traefik/conf.d/bar.yml <<-EOF
http:
  services:
    bar:
      loadBalancer:
        servers:
        - url: "https://server2/"
  routers:
    bar:
      entryPoints:
      - "websecure"
      rule: "Host(\`bar.com\`)"
      middlewares: secHeaders@file
      service: "bar"
EOF

step 'System configs'
sed -i -e 's/modules=ext4/modules=ext4 overlaytmpfs=yes/' /boot/extlinux.conf
sed -i -e 's/tty1::respawn:\/sbin\/getty 38400 tty1/tty1::respawn:\/usr\/sbin\/chroot \/traefik \/bin\/traefik --configfile \/traefik.yml/' /etc/inittab

