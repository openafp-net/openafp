.PHONY: sync-install-scripts

sync-install-scripts:
	curl -sL -o /var/www/install/install.sh https://gitee.com/openafp/openafp-public/raw/master/install.sh
	curl -sL -o /var/www/install/install.ps1 https://gitee.com/openafp/openafp-public/raw/master/install.ps1
	curl -sL -o /var/www/install/latest.json https://gitee.com/openafp/openafp-public/raw/master/latest.json
	systemctl restart caddy
	@echo "install.openafp.net synced"
