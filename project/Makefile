

TARGETS_DIR=/tmp/GenTargets

PRO_ZRDN_FILE=pro_zrdn.sh
RLS_FILE=rls.sh
COMMAND_POST_FILE=command_post.sh
GEN_FILE=GenTargets.sh

PRO1_PARAMS=PRO 1 1200 3800 3825
ZRDN1_PARAMS=ZRDN 1 650 4975 3775
ZRDN2_PARAMS=ZRDN 2 400 4375 3725
ZRDN3_PARAMS=ZRDN 3 550 2925 4575
RLS1_PARAMS=1 3000 9000 5500 90 120 1200 3800 3825
RLS2_PARAMS=2 4000 3000 4000 45 90 1200 3800 3825
RLS3_PARAMS=3 7000 3262 3375 225 200 1200 3800 3825


get_pid_by_name = `ps aux | grep "$(1)" | grep -v grep | head -n1 | tr -s ' ' | cut -d' ' -f 2`
stop_process = kill $(call get_pid_by_name,$(1))

# выполняются все команды, несмотря на ошибки
.IGNORE:

clear:
	./recreate_db.sh
	rm -rf $(TARGETS_DIR)/*
	rm -rf ./temp/*
	rm -rf ./test.test.log

run: clear
	./$(GEN_FILE) > temp/$(GEN_FILE).log 2>&1 &
	./$(COMMAND_POST_FILE) > temp/$(COMMAND_POST_FILE).log 2>&1 &
	
	sleep 1
	
	./$(PRO_ZRDN_FILE) $(PRO1_PARAMS) > logs/$(PRO_ZRDN_FILE).pro1.log 2>&1 &
	./$(PRO_ZRDN_FILE) $(ZRDN1_PARAMS) > logs/$(PRO_ZRDN_FILE).zrdn1.log 2>&1 &
	./$(PRO_ZRDN_FILE) $(ZRDN2_PARAMS) > logs/$(PRO_ZRDN_FILE).zrdn2.log 2>&1 &
	./$(PRO_ZRDN_FILE) $(ZRDN3_PARAMS) > logs/$(PRO_ZRDN_FILE).zrdn3.log 2>&1 &
	
	./$(RLS_FILE) $(RLS1_PARAMS) > logs/$(RLS_FILE).rls1.log 2>&1 &
	./$(RLS_FILE) $(RLS2_PARAMS) > logs/$(RLS_FILE).rls2.log 2>&1 &
	./$(RLS_FILE) $(RLS3_PARAMS) > logs/$(RLS_FILE).rls3.log 2>&1 &

	
stop:
	$(call stop_process,$(PRO_ZRDN_FILE) $(PRO1_PARAMS))
	$(call stop_process,$(PRO_ZRDN_FILE) $(ZRDN1_PARAMS))
	$(call stop_process,$(PRO_ZRDN_FILE) $(ZRDN2_PARAMS))
	$(call stop_process,$(PRO_ZRDN_FILE) $(ZRDN3_PARAMS))
	$(call stop_process,$(RLS_FILE) $(RLS1_PARAMS))
	$(call stop_process,$(RLS_FILE) $(RLS2_PARAMS))
	$(call stop_process,$(RLS_FILE) $(RLS3_PARAMS))
	$(call stop_process,$(GEN_FILE))
	
	$(call stop_process,$(COMMAND_POST_FILE))
	
	# завершение асинхронного процесса (sleep 20 прикрепляется к init, после 20 сек. вернет код возврата)
	$(call stop_process,$(COMMAND_POST_FILE))
	
	$(call stop_process,nc -lk)

watch_db:
	watch -n1 "sqlite3 ./db/messages.db \"SELECT * FROM messages;\" | column -t -s '|' | tail -n 30"
	# -t table, -s separator
