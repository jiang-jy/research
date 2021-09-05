# .hを生成するため
# デバイスプロパティの構造体、関数を宣言する
# rubyコードの一部はcfg_gen.rbから継承された

require "json"
require 'fileutils'
require 'tempfile'

class H_gen
    # Echonet Lite Device Description in JSON
    devdesc_json_fname = "appendix_v3-1-6r5/EL_DeviceDescription_3_1_6r5.json"

    # Read Device Description (String)
    devdesc_json = File.read(devdesc_json_fname)

    # Convert JSON String to Hash
    DevDesc = JSON[devdesc_json]
    Devices = DevDesc["devices"]
    Definitions = DevDesc["definitions"]

    def self.print_default_struct(fileName)
        fileName.puts("#include \"echonet.h\"")
        fileName.puts("#define ECHONET_MAIN_PRIORITY 5
    #define ECHONET_MAIN_STACK_SIZE	1024
    #define EOJ_X3_NODE_PROFILE 1")
        # todo: 優先度、ノードオブジェクト定義
    end

    def self.font_change(name)
        return name.gsub("/"," ").split(/ |\_|\-/).map(&:capitalize).join(" ").gsub(/\s+/, '')
    end

    def self.font_NAME(name)
        return name.upcase.gsub(/\s+/,'_') #先全部替换大写，在把空格替换为下划线
    end

    def self.font_name(name)
        return name.downcase.gsub(/\s+/,'_')
    end


    def self.folder_gen(val)
        className = font_change(val['className']['en'])
        FileUtils.mkdir_p("lib/#{className}/src") # 建立多重路径
        # [2] 各フォルダーの中 ファイルを生成する
        h = File.open("lib/#{className}/src/echonet_main.h","w+")
        print_default_struct(h)

        objNAME = font_NAME(val['className']['en'])
        h.puts("#define EOJ_X3_#{objNAME}_CLASS 1")
        h.puts ("/*Ｖｅｒｓｉｏｎ情報の型*/
    struct version_information_t {
        /* メジャーバージョン(小数点以上) */
        uint8_t major_version_number;
        /* マイナーバージョン(小数点以下) */
        uint8_t minor_version_number;
        /* 電文タイプ */
        uint8_t message_type[2];
    };

    /*メーカーコードの型*/
    struct manufacturer_code_t {
    	/* メーカーコード */
    	uint8_t manufacturer_code[3];
    };

    /*識別番号の型*/
    struct node_identification_number_t {
    	/* 下位通信層IDフィールド */
    	uint8_t lower_communication_id_field;
    	/* メーカーコード */
    	struct manufacturer_code_t manufacturer_code;
    	/* ユニークID部(メーカー独自) */
    	uint8_t unique_id_section[13];
    };

    /*規格Ｖｅｒｓｉｏｎ情報の型*/
    struct standard_version_information_t {
    	/* 固定1(for future reserved) */
    	uint8_t reserved1;
    	/* 固定2(for future reserved) */
    	uint8_t reserved2;
    	/* リリース順をASCIIで示す */
    	uint8_t order_of_release;
    	/* 固定4(for future reserved) */
    	uint8_t reserved4;
    };

    /*ノードプロファイルオブジェクト*/
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
    ")
        objName_jp = val['className']['ja']
        h.puts ("/*#{objName_jp}*/")
        objname = font_name(val['className']['en'])
        h.puts ("struct #{objname}_t {
        /* 動作状態 */
        uint8_t operation_status;
        /* 設置場所 */
        uint8_t installation_location;
        /* 規格Ｖｅｒｓｉｏｎ情報 */
        struct standard_version_information_t standard_version_information;
        /* 異常発生状態 */
        uint8_t fault_status;
        /* メーカーコード */
        struct manufacturer_code_t manufacturer_code;
    ")
        
        # 只要get是required就生成结构体
        val['elProperties'].each{|prop_id,val2|
            if val2['oneOf'] then 

            else
                propName_jp = val2['propertyName']['ja']
                propname_en = font_name(val2['propertyName']['en'])

                if ( val2['accessRule']['set'] == 'required' )then 
                    h.puts ("   /*#{propName_jp}*/\n    uint8_t #{propname_en};\n};")

                    h.puts ("extern struct node_profile_object_t local_node_data;\nextern struct #{objname}_t #{objname}_class_data;")
                    h.puts ("EPRP_SETTER onoff_prop_set;\nEPRP_SETTER alarm_prop_set;\nEPRP_SETTER #{propname_en}_prop_set;")

                    h.puts("void echonet_main_task(intptr_t exinf);")
                end

            end

        }
    end

    def self.folder_gen_argv(val, dev)
        className = font_change(val['className']['en'])
        dev.each{|arg|
            if arg.gsub("\"","").chomp == val['className']['en'] then
                FileUtils.mkdir_p("lib/#{className}/src") # 建立多重路径
                # [2] 各フォルダーの中 ファイルを生成する
                h = File.open("lib/#{className}/src/echonet_main.h","w+")
                print_default_struct(h)

                objNAME = font_NAME(val['className']['en'])
                h.puts("#define EOJ_X3_#{objNAME}_CLASS 1")
                h.puts ("/*Ｖｅｒｓｉｏｎ情報の型*/
            struct version_information_t {
                /* メジャーバージョン(小数点以上) */
                uint8_t major_version_number;
                /* マイナーバージョン(小数点以下) */
                uint8_t minor_version_number;
                /* 電文タイプ */
                uint8_t message_type[2];
            };

            /*メーカーコードの型*/
            struct manufacturer_code_t {
                /* メーカーコード */
                uint8_t manufacturer_code[3];
            };

            /*識別番号の型*/
            struct node_identification_number_t {
                /* 下位通信層IDフィールド */
                uint8_t lower_communication_id_field;
                /* メーカーコード */
                struct manufacturer_code_t manufacturer_code;
                /* ユニークID部(メーカー独自) */
                uint8_t unique_id_section[13];
            };

            /*規格Ｖｅｒｓｉｏｎ情報の型*/
            struct standard_version_information_t {
                /* 固定1(for future reserved) */
                uint8_t reserved1;
                /* 固定2(for future reserved) */
                uint8_t reserved2;
                /* リリース順をASCIIで示す */
                uint8_t order_of_release;
                /* 固定4(for future reserved) */
                uint8_t reserved4;
            };

            /*ノードプロファイルオブジェクト*/
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
            ")
                objName_jp = val['className']['ja']
                h.puts ("/*#{objName_jp}*/")
                objname = font_name(val['className']['en'])
                h.puts ("struct #{objname}_t {
                /* 動作状態 */
                uint8_t operation_status;
                /* 設置場所 */
                uint8_t installation_location;
                /* 規格Ｖｅｒｓｉｏｎ情報 */
                struct standard_version_information_t standard_version_information;
                /* 異常発生状態 */
                uint8_t fault_status;
                /* メーカーコード */
                struct manufacturer_code_t manufacturer_code;
            ")
                
                # 只要get是required就生成结构体
                val['elProperties'].each{|prop_id,val2|
                    if val2['oneOf'] then 

                    else
                        propName_jp = val2['propertyName']['ja']
                        propname_en = font_name(val2['propertyName']['en'])

                        if ( val2['accessRule']['set'] == 'required' )then 
                            h.puts ("   /*#{propName_jp}*/\n    uint8_t #{propname_en};\n};")

                            h.puts ("extern struct node_profile_object_t local_node_data;\nextern struct #{objname}_t #{objname}_class_data;")
                            h.puts ("EPRP_SETTER onoff_prop_set;\nEPRP_SETTER alarm_prop_set;\nEPRP_SETTER #{propname_en}_prop_set;")

                            h.puts("void echonet_main_task(intptr_t exinf);")
                        end

                    end

                }
            end
        }
    end

    def self.h_gen
        dev = ARGV
        Devices.each{ |id, val|
            # [1] classNameを持っていく　フォルダーを作る
            if val['oneOf'] then
                val['oneOf'].each{|val2|
                    if dev.empty? then
                        folder_gen(val2)
                    else
                        folder_gen_argv(val2, dev)
                    end
                }
            elsif val['className'] == nil then
                #print "*** #{id} has no class name ***\n"
            elsif val['className']['en'] then
                if dev.empty? then
                    folder_gen(val)
                else
                    folder_gen_argv(val, dev)
                end
                #print( "#{val['className']['en']} = #{id}\n" )
            elsif val['className']['ja'] then
                #print( "#{val['className']['ja']} = #{id}\n" )
            else
                #print "### #{id} has class name but has neither 'ja' nor 'en' ***\n"
            end
        }
    end
end

H_gen.h_gen