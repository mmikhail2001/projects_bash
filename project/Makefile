

TARGETS_DIR=/tmp/GenTargets
PRO_ZRDN_FILE=pro_zrdn.sh
GEN_FILE=GenTargets.sh
COMMAND_POST_FILE=command_post.sh

PRO1_PARAMS=PRO 1 12000000 3800 3825
ZRDN1_PARAMS=ZRDN 1 6500000 4975 3775
ZRDN2_PARAMS=ZRDN 2 4000000 4375 3725
ZRDN3_PARAMS=ZRDN 3 5500000 2925 4575

get_pid_by_name = `ps aux | grep "$(1)" | grep -v grep | head -n1 | tr -s ' ' | cut -d' ' -f 2`
stop_process = kill $(call get_pid_by_name,$(1))

clear:
	./recreate_db.sh
	rm -rf $(TARGETS_DIR)/*
	rm -rf ./temp/*

run: clear
	./$(PRO_ZRDN_FILE) $(PRO1_PARAMS) > temp/$(PRO_ZRDN_FILE).pro1.log 2>&1 &
	# ./$(PRO_ZRDN_FILE) $(ZRDN1_PARAMS) > temp/$(PRO_ZRDN_FILE).zrdn1.log 2>&1 &
	# ./$(PRO_ZRDN_FILE) $(ZRDN2_PARAMS) > temp/$(PRO_ZRDN_FILE).zrdn2.log 2>&1 &
	# ./$(PRO_ZRDN_FILE) $(ZRDN3_PARAMS) > temp/$(PRO_ZRDN_FILE).zrdn3.log 2>&1 &
	./$(GEN_FILE) > temp/$(GEN_FILE).log 2>&1 &
	./$(COMMAND_POST_FILE) > temp/$(COMMAND_POST_FILE).log 2>&1 &
	
stop:
	$(call stop_process,$(PRO_ZRDN_FILE) $(PRO1_PARAMS))
	# $(call stop_process,$(PRO_ZRDN_FILE) $(ZRDN1_PARAMS))
	# $(call stop_process,$(PRO_ZRDN_FILE) $(ZRDN2_PARAMS))
	# $(call stop_process,$(PRO_ZRDN_FILE) $(ZRDN3_PARAMS))
	# $(call stop_process,$(GEN_FILE))
	$(call stop_process,$(COMMAND_POST_FILE))
	$(call stop_process,ncat -l --keep-open)

watch_db:
	watch -n1 "sqlite3 ./db/messages.db \"SELECT * FROM messages;\" | tail -n 20"
