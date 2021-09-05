/*
 *  TOPPERS ECHONET Lite Communication Middleware
 * 
 *  Copyright (C) 2014 Cores Co., Ltd. Japan
 * 
 *  上記著作権者は，以下の(1)～(4)の条件を満たす場合に限り，本ソフトウェ
 *  ア（本ソフトウェアを改変したものを含む．以下同じ）を使用・複製・改
 *  変・再配布（以下，利用と呼ぶ）することを無償で許諾する．
 *  (1) 本ソフトウェアをソースコードの形で利用する場合には，上記の著作
 *      権表示，この利用条件および下記の無保証規定が，そのままの形でソー
 *      スコード中に含まれていること．
 *  (2) 本ソフトウェアを，ライブラリ形式など，他のソフトウェア開発に使
 *      用できる形で再配布する場合には，再配布に伴うドキュメント（利用
 *      者マニュアルなど）に，上記の著作権表示，この利用条件および下記
 *      の無保証規定を掲載すること．
 *  (3) 本ソフトウェアを，機器に組み込むなど，他のソフトウェア開発に使
 *      用できない形で再配布する場合には，次のいずれかの条件を満たすこ
 *      と．
 *    (a) 再配布に伴うドキュメント（利用者マニュアルなど）に，上記の著
 *        作権表示，この利用条件および下記の無保証規定を掲載すること．
 *    (b) 再配布の形態を，別に定める方法によって，TOPPERSプロジェクトに
 *        報告すること．
 *  (4) 本ソフトウェアの利用により直接的または間接的に生じるいかなる損
 *      害からも，上記著作権者およびTOPPERSプロジェクトを免責すること．
 *      また，本ソフトウェアのユーザまたはエンドユーザからのいかなる理
 *      由に基づく請求からも，上記著作権者およびTOPPERSプロジェクトを
 *      免責すること．
 * 
 *  本ソフトウェアは，無保証で提供されているものである．上記著作権者お
 *  よびTOPPERSプロジェクトは，本ソフトウェアに関して，特定の使用目的
 *  に対する適合性も含めて，いかなる保証も行わない．また，本ソフトウェ
 *  アの利用により直接的または間接的に生じたいかなる損害に関しても，そ
 *  の責任を負わない．
 * 
 *  @(#) $Id$
 */

/* 
 *  サンプルプログラム(1)の本体
 */

#include <kernel.h>
#include <t_syslog.h>
#include <t_stdlib.h>
#include <sil.h>
#include <string.h>
#include "syssvc/serial.h"
#include "syssvc/syslog.h"
#include "kernel_cfg.h"
#include "main.h"
#include "echonet_cfg.h"
#include "v850_ca850/v850esjh3e.h"

/* TODO: MACアドレスを設定 */
uint8_t mac_addr[6] = { 0x00, 0x12, 0x34, 0x56, 0x78, 0x9A };

/* TODO: メーカーコードを設定 */
#define MAKER_CODE	0x00, 0x00, 0xB3	/* TOPPERSプロジェクト */

/* ノードプロファイルオブジェクト */
struct node_profile_object_t local_node_data = {
	0x30,	/* 動作状態 */
	{ 0x01, 0x0A, 0x01, 0x00 },	/* Ｖｅｒｓｉｏｎ情報 */
	{
		0xFE,	/* 下位通信層IDフィールド */
		{ MAKER_CODE },	/* メーカーコード */
		{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, },	/* ユニークID部(メーカー独自) */
	},
	{ MAKER_CODE },	/* メーカーコード */
};

/* 一般照明クラス */
struct general_lighting_t general_lighting_class_data = {
	0x30,	/* 動作状態 */
	0x41,	/* 点灯モード設定 */
	0x00,	/* 設置場所 */
	{ 0x00, 0x00, 'C', 0x00 },	/* 規格Ｖｅｒｓｉｏｎ情報 */
	0x41,	/* 異常発生状態 */
	{ MAKER_CODE },	/* メーカーコード */
};

/*
 * 動作状態ON/OFF設定関数（0x30, 0x31のみ受け付け）
 */
int onoff_prop_set(const EPRPINIB *item, const void *src, int size, bool_t *anno)
{
	/* サイズが１以外は受け付けない */
	if(size != 1)
		return 0;

	*anno = *((uint8_t*)item->exinf) != *((uint8_t*)src);

	switch(*(uint8_t *)src){
	/* ONの場合 */
	case 0x30:
		*((uint8_t *)item->exinf) = *((uint8_t *)src);
		/* TODO: ONの場合の処理*/
		break;
	/* OFFの場合 */
	case 0x31:
		*((uint8_t *)item->exinf) = *((uint8_t *)src);
		/* TODO: OFFの場合の処理*/
		break;
	/* 0x30か0x31以外は受け付けない */
	default:
		return 0;
	}

	return 1;
}



/*
 * 点灯モード設定設定関数
 */
int general_lighting_lighting_mode_setting_set(const EPRPINIB *item, const void *src, int size, bool_t *anno)
{
	/* サイズが1以外は受け付けない */
	if(size != 1)
		return 0;

	switch(*(uint8_t *)src){
	/* 自動の場合 */
	case 0x41:
		*((uint8_t *)item->exinf) = *((uint8_t *)src);
		/* TODO: 自動の場合の処理*/
		break;
	/* 通常灯の場合 */
	case 0x42:
		*((uint8_t *)item->exinf) = *((uint8_t *)src);
		/* TODO: 通常灯の場合の処理*/
		break;
	/* 常夜灯の場合 */
	case 0x43:
		*((uint8_t *)item->exinf) = *((uint8_t *)src);
		/* TODO: 常夜灯の場合の処理*/
		break;
	/* カラー灯の場合 */
	case 0x45:
		*((uint8_t *)item->exinf) = *((uint8_t *)src);
		/* TODO: カラー灯の場合の処理*/
		break;
	default:
		/* 上記以外は受け付けない */
		return 0;
	}

	return 1;
}

/*
 * 異常発生状態設定関数（0x41, 0x42のみ受け付け）
 */
int alarm_prop_set(const EPRPINIB *item, const void *src, int size, bool_t *anno)
{
	ER ret;
	uint8_t data[1];

	/* サイズが１以外は受け付けない */
	if(size != 1)
		return 0;

	*anno = *((uint8_t *)item->exinf) != *((uint8_t *)src);

	switch(*(uint8_t *)src){
	/* 異常発生ありの場合 */
	case 0x41:
	/* 異常発生なしの場合 */
	case 0x42:
		*((uint8_t *)item->exinf) = *((uint8_t *)src);
		break;
	/* 0x41か0x42以外は受け付けない */
	default:
		return 0;
	}

	return 1;
}



static void main_initialize();
static TMO main_get_timer();
static void main_progress(TMO interval);
static void main_recv_esv(T_EDATA *esv);
static void main_break_wait(uint8_t *brkdat, int32_t len);
static void main_timeout();

/*
 *  メインタスク
 */
void main_task(intptr_t exinf)
{
	ER ret, ret2;
	SYSTIM prev, now;
	TMO timer;
	T_EDATA *esv;
	uint8_t brkdat[64];
	int32_t len;

	/* TINETが起動するまで待つ */
	ret = tslp_tsk(1000);
	if(ret != E_TMOUT)
		return;

	/* ECHONETミドルウェアを起動 */
	ret = act_tsk(ECN_UDP_TASK);
	if(ret != E_OK)
		return;

	/* 初期化 */
	main_initialize();

	ret2 = get_tim(&now);
	if (ret2 != E_OK){
		syslog(LOG_ERROR, "get_tim");
		return;
	}

	for(;;){
		prev = now;

		/* タイマー取得 */
		timer = main_get_timer();

		/* 応答電文待ち */
		ret = ecn_trcv_esv(&esv, timer);
		if ((ret != E_OK) && (ret != E_WBLK) && (ret != E_TMOUT)){
			syslog(LOG_ERROR, "ecn_trcv_esv");
			break;
		}

		ret2 = get_tim(&now);
		if (ret2 != E_OK){
			syslog(LOG_ERROR, "get_tim");
			break;
		}

		/* 時間経過 */
		main_progress(now - prev);

		/* Echonet電文受信の場合 */
		if (ret == E_OK) {
			/* Echonet電文受信処理 */
			main_recv_esv(esv);

			/* 領域解放 */
			ret = ecn_rel_esv(esv);
			if (ret != E_OK){
				syslog(LOG_ERROR, "ecn_rel_esv");
				break;
			}
		}
		/* 応答電文待ちの割り込みの場合 */
		else if (ret == E_WBLK) {
			/* 応答電文待ちの割り込みデータ取得 */
			ret = ecn_get_brk_dat(esv, brkdat, sizeof(brkdat), &len);
			if (ret != E_OK){
				syslog(LOG_ERROR, "ecn_get_brk_dat");
				break;
			}

			/* 応答電文待ちの割り込み処理 */
			main_break_wait(brkdat, len);

			/* 領域解放 */
			ret = ecn_rel_esv(esv);
			if (ret != E_OK){
				syslog(LOG_ERROR, "ecn_rel_esv");
				break;
			}
		}

		/* タイムアウト処理 */
		main_timeout();
	}
}

enum main_state_t{
	main_state_idle,
};

TMO main_timer = TMO_FEVR;
enum main_state_t main_state = main_state_idle;

/*
 * 初期化
 */
static void main_initialize()
{
}

/*
 * タイマー取得
 */
static TMO main_get_timer()
{
	return main_timer;
}

/*
 * 時間経過
 */
static void main_progress(TMO interval)
{
	if(main_timer == TMO_FEVR)
		return;

	main_timer -= interval;
	if(main_timer < 0){
		main_timer = 0;
	}
}

/*
 * Echonet電文受信処理
 */
static void main_recv_esv(T_EDATA *esv)
{
	ER ret;
	uint8_t epc;
	uint8_t pdc;
	uint8_t p_edt[256];
	T_ENUM_EPC enm;

	ret = ecn_itr_ini(&enm, esv);
	if(ret != E_OK){
		syslog(LOG_ERROR, "ecn_itr_ini");
		return;
	}

	for(;;) {
		while((ret = ecn_itr_nxt(&enm, &epc, &pdc, p_edt)) == E_OK) {
			switch (epc) {
			case 0x80:
				break;
			case 0x81:
				break;
			}
		}
		if(ret != E_BOVR){
			syslog(LOG_ERROR, "ecn_itr_nxt");
			break;
		}
		if(enm.is_eof)
			break;
	}
}

/*
 * 応答電文待ちの割り込み処理
 */
static void main_break_wait(uint8_t *brkdat, int32_t len)
{
	switch(main_state){
	case main_state_idle:
		break;
	}
}

/*
 * タイムアウト処理
 */
static void main_timeout()
{
	if(main_timer != 0)
		return;

	switch(main_state){
	case main_state_idle:
		break;
	}
}
