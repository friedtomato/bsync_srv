SCR_DIR=$(BSYNC_SCR_PATH)
BIN_DIR=$(BSYNC_BIN_PATH)
USB_BACKUP_DIR=$(BSYNC_USB_PATH)/backup
MMC_BACKUP_DIR=$(BSYNC_MMC_PATH)/backup
DATE=`date +%F_%s`
HOSTNAME=`hostname`
SET_RUN_DIR=$(BIN_DIR)
MAIN_BSYNC_RUN=main_bsync_run.sh

BASHRC_DIR=/home/pi
VIDEO_DIR=/home/pi/video/jack

backup:
	@echo "backing up $(SCR_DIR) and $(BIN_DIR)"
	@cp -r $(SCR_DIR)/* $(USB_BACKUP_DIR)/dev
	@cp -r $(BIN_DIR)/* $(USB_BACKUP_DIR)/bin
	@cp -r $(SCR_DIR)/* $(MMC_BACKUP_DIR)/dev
	@cp -r $(BIN_DIR)/* $(MMC_BACKUP_DIR)/bin
	@cp $(BASHRC_DIR)/.bashrc $(USB_BACKUP_DIR)
	@cp $(BASHRC_DIR)/.bashrc $(MMC_BACKUP_DIR)
	@cp $(BASHRC_DIR)/bsync_srv_vardef.sh $(USB_BACKUP_DIR)
	@cp $(BASHRC_DIR)/bsync_srv_vardef.sh $(MMC_BACKUP_DIR)
	@echo $(DATE)
	@tar -czvf $(USB_BACKUP_DIR)_$(DATE)_$(HOSTNAME).tgz $(USB_BACKUP_DIR)
	@tar -czvf $(MMC_BACKUP_DIR)_$(DATE)_$(HOSTNAME).tgz $(MMC_BACKUP_DIR)

vsync:
	scp $(VIDEO_DIR)/* 192.168.0.2:$(VIDEO_DIR)
	scp $(VIDEO_DIR)/* 192.168.0.3:$(VIDEO_DIR)
	scp $(VIDEO_DIR)/* 192.168.0.4:$(VIDEO_DIR)
	scp $(VIDEO_DIR)/* 192.168.0.5:$(VIDEO_DIR)
	scp $(VIDEO_DIR)/* 192.168.0.6:$(VIDEO_DIR)
	scp $(VIDEO_DIR)/* 192.168.0.7:$(VIDEO_DIR)
	scp $(VIDEO_DIR)/* 192.168.0.8:$(VIDEO_DIR)
	scp $(VIDEO_DIR)/* 192.168.0.9:$(VIDEO_DIR)

halt:
	ssh 192.168.0.2 'sudo halt &'
	ssh 192.168.0.3 'sudo halt &'
	ssh 192.168.0.4 'sudo halt &'
	ssh 192.168.0.5 'sudo halt &'
	ssh 192.168.0.6 'sudo halt &'
	ssh 192.168.0.7 'sudo halt &'
	ssh 192.168.0.8 'sudo halt &'
	ssh 192.168.0.9 'sudo halt &'

reboot:
	@ssh 192.168.0.2 'sudo reboot &'
	@ssh 192.168.0.3 'sudo reboot &'
	@ssh 192.168.0.4 'sudo reboot &'
	@ssh 192.168.0.5 'sudo reboot &'
	@ssh 192.168.0.6 'sudo reboot &'
	@ssh 192.168.0.7 'sudo reboot &'
	@ssh 192.168.0.8 'sudo reboot &'
	@ssh 192.168.0.9 'sudo reboot &'

reboot2:
	@ssh 192.168.0.2 'sudo reboot &'
reboot3:
	@ssh 192.168.0.3 'sudo reboot &'
reboot4:
	@ssh 192.168.0.4 'sudo reboot &'
reboot5:
	@ssh 192.168.0.5 'sudo reboot &'
reboot6:
	@ssh 192.168.0.6 'sudo reboot &'
reboot7:
	@ssh 192.168.0.7 'sudo reboot &'
reboot8:
	@ssh 192.168.0.8 'sudo reboot &'
reboot9:
	@ssh 192.168.0.9 'sudo reboot &'

run:
	@ssh 192.168.0.1 'sed -i ''s/BSYNC_RUN=n/BSYNC_RUN=r/'' /home/pi/bsync_srv_vardef.sh'
	@ssh 192.168.0.2 'sed -i ''s/BSYNC_RUN=n/BSYNC_RUN=r/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.3 'sed -i ''s/BSYNC_RUN=n/BSYNC_RUN=r/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.4 'sed -i ''s/BSYNC_RUN=n/BSYNC_RUN=r/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.5 'sed -i ''s/BSYNC_RUN=n/BSYNC_RUN=r/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.6 'sed -i ''s/BSYNC_RUN=n/BSYNC_RUN=r/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.7 'sed -i ''s/BSYNC_RUN=n/BSYNC_RUN=r/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.8 'sed -i ''s/BSYNC_RUN=n/BSYNC_RUN=r/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.9 'sed -i ''s/BSYNC_RUN=n/BSYNC_RUN=r/'' /home/pi/bsync_cli_vardef.sh'

norun: 
	@ssh 192.168.0.1 'sed -i ''s/BSYNC_RUN=r/BSYNC_RUN=n/'' /home/pi/bsync_srv_vardef.sh'
	@ssh 192.168.0.2 'sed -i ''s/BSYNC_RUN=r/BSYNC_RUN=n/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.3 'sed -i ''s/BSYNC_RUN=r/BSYNC_RUN=n/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.4 'sed -i ''s/BSYNC_RUN=r/BSYNC_RUN=n/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.5 'sed -i ''s/BSYNC_RUN=r/BSYNC_RUN=n/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.6 'sed -i ''s/BSYNC_RUN=r/BSYNC_RUN=n/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.7 'sed -i ''s/BSYNC_RUN=r/BSYNC_RUN=n/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.8 'sed -i ''s/BSYNC_RUN=r/BSYNC_RUN=n/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.9 'sed -i ''s/BSYNC_RUN=r/BSYNC_RUN=n/'' /home/pi/bsync_cli_vardef.sh'
cmanual:	
	@ssh 192.168.0.2 'sed -i ''s/BSYNC_MOD=a/BSYNC_MOD=m/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.3 'sed -i ''s/BSYNC_MOD=a/BSYNC_MOD=m/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.4 'sed -i ''s/BSYNC_MOD=a/BSYNC_MOD=m/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.5 'sed -i ''s/BSYNC_MOD=a/BSYNC_MOD=m/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.6 'sed -i ''s/BSYNC_MOD=a/BSYNC_MOD=m/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.7 'sed -i ''s/BSYNC_MOD=a/BSYNC_MOD=m/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.8 'sed -i ''s/BSYNC_MOD=a/BSYNC_MOD=m/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.9 'sed -i ''s/BSYNC_MOD=a/BSYNC_MOD=m/'' /home/pi/bsync_cli_vardef.sh'
cauto:	
	@ssh 192.168.0.2 'sed -i ''s/BSYNC_MOD=m/BSYNC_MOD=a/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.3 'sed -i ''s/BSYNC_MOD=m/BSYNC_MOD=a/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.4 'sed -i ''s/BSYNC_MOD=m/BSYNC_MOD=a/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.5 'sed -i ''s/BSYNC_MOD=m/BSYNC_MOD=a/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.6 'sed -i ''s/BSYNC_MOD=m/BSYNC_MOD=a/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.7 'sed -i ''s/BSYNC_MOD=m/BSYNC_MOD=a/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.8 'sed -i ''s/BSYNC_MOD=m/BSYNC_MOD=a/'' /home/pi/bsync_cli_vardef.sh'
	@ssh 192.168.0.9 'sed -i ''s/BSYNC_MOD=m/BSYNC_MOD=a/'' /home/pi/bsync_cli_vardef.sh'

