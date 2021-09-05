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

#ifndef _MAIN_H_
#define _MAIN_H_

/*
 *		サンプルプログラム(1)のヘッダファイル
 */

/*
 *  ターゲット依存の定義
 */
#include "target_test.h"
#include "echonet.h"

/*
 *  各タスクの優先度の定義
 */

#define MAIN_PRIORITY	5		/* メインタスクの優先度 */

#define MAIN_STACK_SIZE	1024	/* スタック領域のサイズ */

#define EOJ_X3_LOCAL_NODE 1	/* ノードプロファイルオブジェクトのインスタンスコード */

#define EOJ_X3_GENERAL_LIGHTING_CLASS 1	/* 一般照明クラスのインスタンスコード */



/*
 *  関数のプロトタイプ宣言
 */
#ifndef TOPPERS_MACRO_ONLY

extern void main_task(intptr_t exinf);

#ifdef __CA850__
#pragma pack(1)
#elif __RX
#pragma pack
#elif _MSC_VER
#pragma pack(push, 1)
#endif

/*
 *  Ｖｅｒｓｉｏｎ情報の型
 */
struct version_information_t {
	/* メジャーバージョン(小数点以上) */
	uint8_t major_version_number;
	/* マイナーバージョン(小数点以下) */
	uint8_t minor_version_number;
	/* 電文タイプ */
	uint8_t message_type[2];
};

/*
 *  識別番号の型
 */
struct node_identification_number_t {
	/* 下位通信層IDフィールド */
	uint8_t lower_communication_id_field;
	/* メーカーコード */
	struct manufacturer_code_t manufacturer_code;
	/* ユニークID部(メーカー独自) */
	uint8_t unique_id_section[13];
};

/*
 *  メーカーコードの型
 */
struct manufacturer_code_t {
	/* メーカーコード */
	uint8_t manufacturer_code[3];
};

/*
 *  規格Ｖｅｒｓｉｏｎ情報の型
 */
struct standard_version_information_t {
	/* 固定1(for future reserved) */
	uint8_t reserved;
	/* 固定2(for future reserved) */
	uint8_t reserved;
	/* リリース順をASCIIで示す */
	uint8_t order_of_release;
	/* 固定4(for future reserved) */
	uint8_t reserved;
};


/*
 *  ノードプロファイルオブジェクト
 */
struct node_profile_object_t {
	/* 動作状態 */
	uint8_t operation_status;
	/* Ｖｅｒｓｉｏｎ情報 */
	struct version_information_t version_information;
	/* 識別番号 */
	struct node_identification_number_t identification_number;
	/* メーカーコード */
	struct manufacturer_code_t manufacturer_code;
};

/*
 *  一般照明クラス
 */
struct general_lighting_t {
	/* 動作状態 */
	uint8_t operation_status;
	/* 点灯モード設定 */
	uint8_t lighting_mode_setting;
	/* 設置場所 */
	uint8_t installation_location;
	/* 規格Ｖｅｒｓｉｏｎ情報 */
	struct standard_version_information_t standard_version_information;
	/* 異常発生状態 */
	uint8_t fault_status;
	/* メーカーコード */
	struct manufacturer_code_t manufacturer_code;
};



#ifdef __CA850__
#pragma pack(8)
#elif __RX
#pragma unpack
#elif _MSC_VER
#pragma pack(pop)
#endif

extern struct node_profile_object_t local_node_data;	/* ノードプロファイルオブジェクトのデータ */

extern struct general_lighting_t general_lighting_class_data;	/* 一般照明クラスのデータ */

EPRP_SETTER onoff_prop_set;
EPRP_SETTER general_lighting_lighting_mode_setting_set;
EPRP_SETTER alarm_prop_set;



#endif /* TOPPERS_MACRO_ONLY */

#endif	/* of #ifndef _MAINN_H_ */
