# 2021/05/18 cfgファイルを生成するため
# フォルダー構成
#     lib/#{className}/src/echonet_main.cfg 
#                         echonet_main.c 
#                         t#{className}.c 
#                         #{className}.cdl

# cfg構造：ノードオブジェクト + デバイス
#     ECN_CRE_EOBJ()
#     ECN_DEF_EPRP()
# cfg注意点：access ruleはrequiredのみ,デバイスプロパティはsuper classから継承？

# 2021/05/25 生成正确的路径和空文件，验证之前的方法可行性


require "json"
require 'fileutils'
require 'tempfile'

class Cfg_gen
    # Echonet Lite Device Description in JSON
    devdesc_json_fname = "appendix_v3-1-6r5/EL_DeviceDescription_3_1_6r5.json"

    # Read Device Description (String)
    devdesc_json = File.read(devdesc_json_fname)

    # Convert JSON String to Hash
    DevDesc = JSON[devdesc_json]
    Devices = DevDesc["devices"]
    Definitions = DevDesc["definitions"]

    def self.print_nodeprofile(fileName)
        fileName.puts ("
    #include \"main.h\"
    #include \"echonet.h\"
    #include \"echonet_main.h\"
    INCLUDE(\"echonet_asp.cfg\");
    INCLUDE(\"echonet_udp.cfg\");

    CRE_TSK(ECHONET_MAIN_TASK, { TA_ACT, 0, echonet_main_task, ECHONET_MAIN_PRIORITY, ECHONET_MAIN_STACK_SIZE, NULL });
    /*ノードプロファイルオブジェクト*/
    ECN_CRE_EOBJ (LOCAL_NODE_EOBJ, { EOBJ_LOCAL_NODE, EOBJ_NULL, 0, EOJ_X1_PROFILE, EOJ_X2_NODE_PROFILE, EOJ_X3_NODE_PROFILE });\n
    /* 動作状態 */
    ECN_DEF_EPRP (LOCAL_NODE_EOBJ, { 0x80, EPC_RULE_SET | EPC_RULE_GET, 1, (intptr_t)&local_node_data.operation_status, (EPRP_SETTER *)onoff_prop_set, (EPRP_GETTER *)ecn_data_prop_get });\n
    /* Ｖｅｒｓｉｏｎ情報 */
    ECN_DEF_EPRP (LOCAL_NODE_EOBJ, { 0x82, EPC_RULE_GET, 4, (intptr_t)&local_node_data.version_information, (EPRP_SETTER *)ecn_data_prop_set, (EPRP_GETTER *)ecn_data_prop_get });\n
    /* 識別番号 */
    ECN_DEF_EPRP (LOCAL_NODE_EOBJ, { 0x83, EPC_RULE_GET, 17, (intptr_t)&local_node_data.identification_number, (EPRP_SETTER *)ecn_data_prop_set, (EPRP_GETTER *)ecn_data_prop_get });\n
    /* メーカーコード */
    ECN_DEF_EPRP (LOCAL_NODE_EOBJ, { 0x8A, EPC_RULE_GET, 3, (intptr_t)&local_node_data.manufacturer_code, (EPRP_SETTER *)ecn_data_prop_set, (EPRP_GETTER *)ecn_data_prop_get });

    ")
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
        cfg = File.open("lib/#{className}/src/echonet_main.cfg","w+")
        print_nodeprofile(cfg)
        objName_jp = val['className']['ja']
        cfg.puts ("/*#{objName_jp}*/")
        objNAME = font_NAME(val['className']['en'])
        cfg.puts ("ECN_CRE_EOBJ(#{objNAME}_CLASS_EOBJ, {EOBJ_DEVICE, LOCAL_NODE_EOBJ, 0, EOJ_X1_AMENITY, EOJ_X2_#{objNAME}_CLASS, EOJ_X3_#{objNAME}_CLASS});\n
        ")
        objname = font_name(val['className']['en'])
        cfg.puts ("/* 動作状態 */
    ECN_DEF_EPRP (#{objNAME}_CLASS_EOBJ, { 0x80, EPC_RULE_SET | EPC_RULE_GET | EPC_ANNOUNCE, 1, (intptr_t)&#{objname}_class_data.operation_status, (EPRP_SETTER *)onoff_prop_set, (EPRP_GETTER *)ecn_data_prop_get });\n
    /* 設置場所 */
    ECN_DEF_EPRP (#{objNAME}_CLASS_EOBJ, { 0x81, EPC_RULE_SET | EPC_RULE_GET | EPC_ANNOUNCE, 1, (intptr_t)&#{objname}_class_data.installation_location, (EPRP_SETTER *)ecn_data_prop_set, (EPRP_GETTER *)ecn_data_prop_get });\n
    /* 規格Ｖｅｒｓｉｏｎ情報 */
    ECN_DEF_EPRP (#{objNAME}_CLASS_EOBJ, { 0x82, EPC_RULE_GET, 4, (intptr_t)&#{objname}_class_data.standard_version_information, (EPRP_SETTER *)ecn_data_prop_set, (EPRP_GETTER *)ecn_data_prop_get });\n
    /* 異常発生状態 */
    ECN_DEF_EPRP (#{objNAME}_CLASS_EOBJ, { 0x88, EPC_RULE_GET | EPC_ANNOUNCE, 1, (intptr_t)&#{objname}_class_data.fault_status, (EPRP_SETTER *)alarm_prop_set, (EPRP_GETTER *)ecn_data_prop_get });\n
    /* メーカーコード */
    ECN_DEF_EPRP (#{objNAME}_CLASS_EOBJ, { 0x8A, EPC_RULE_GET, 3, (intptr_t)&#{objname}_class_data.manufacturer_code, (EPRP_SETTER *)ecn_data_prop_set, (EPRP_GETTER *)ecn_data_prop_get });

    ")

        val['elProperties'].each{|prop_id,val2| 
            if val2['oneOf'] then
            else
                # val2['accessRule'].each{|rule_key,rule_value| #判断accessrule里面有哪个是required
                #     if rule_value == "required" then
                #         rule = Array.push(rule_key)
                #     end
                #     unless rule.size == 0 then # 如果存在reuqired，那么输出当前的属性信息
                #     end

                # rule里面必定存在get，因此可以先判断get是否是required，如果是那么继续解析data
                # 最后再判断set是否是required
                if val2['accessRule']['get'] == 'required' then
                    propName_jp = val2['propertyName']['ja']
                    propname_en = font_name(val2['propertyName']['en'])
                    cfg.puts ("/*#{propName_jp}*/")
                    if val2['accessRule']['set'] == 'required' then 
                        if val2['data']['$ref'] then
                            ref = val2['data']['$ref'].sub( /#\/definitions\//, "" )
                            val3 = Definitions[ref]
                            if val3['type'] == 'state' then
                                size = val3['size']
                            elsif val3['type'] == 'raw' then
                                size = val3['minSize']
                            else size = 'NULL'
                            end 
                        end   
                        cfg.puts ("ECN_DEF_EPRP(#{objNAME}_CLASS_EOBJ, {#{prop_id}, EPC_RULE_SET | EPC_RULE_GET, #{size}, (intptr_t)&#{objname}_class_data.#{propname_en}, (EPRP_SETTER *)#{propname_en}_prop_set, (EPRP_GETTER *)ecn_data_prop_get });\n
                        ")
                    else
                        if val2['data']['$ref'] then
                            ref = val2['data']['$ref'].sub( /#\/definitions\//, "" )
                            val3 = Definitions[ref]
                            if val3['type'] == 'state' then
                                size = val3['size']
                            elsif val3['type'] == 'raw' then
                                size = val3['minSize']
                            else size = 'NULL'
                            end 
                        end
                        cfg.puts ("ECN_DEF_EPRP(#{objNAME}_CLASS_EOBJ, {#{prop_id}, EPC_RULE_GET, #{size}, (intptr_t)&#{objname}_class_data.#{propname_en}, (EPRP_GETTER *)ecn_data_prop_get });\n
                        ")
                    end
                end
            end
        }

        cfg.close
    end

    def self.folder_gen_argv(val, dev)
        className = font_change(val['className']['en'])
        dev.each{|arg|
            if arg.gsub("\"","").chomp == val['className']['en'] then
                FileUtils.mkdir_p("lib/#{className}/src") # 建立多重路径
                # [2] 各フォルダーの中 ファイルを生成する
                cfg = File.open("lib/#{className}/src/echonet_main.cfg","w+")
                print_nodeprofile(cfg)
                objName_jp = val['className']['ja']
                cfg.puts ("/*#{objName_jp}*/")
                objNAME = font_NAME(val['className']['en'])
                cfg.puts ("ECN_CRE_EOBJ(#{objNAME}_CLASS_EOBJ, {EOBJ_DEVICE, LOCAL_NODE_EOBJ, 0, EOJ_X1_AMENITY, EOJ_X2_#{objNAME}_CLASS, EOJ_X3_#{objNAME}_CLASS});\n
                ")
                objname = font_name(val['className']['en'])
                cfg.puts ("/* 動作状態 */
            ECN_DEF_EPRP (#{objNAME}_CLASS_EOBJ, { 0x80, EPC_RULE_SET | EPC_RULE_GET | EPC_ANNOUNCE, 1, (intptr_t)&#{objname}_class_data.operation_status, (EPRP_SETTER *)onoff_prop_set, (EPRP_GETTER *)ecn_data_prop_get });\n
            /* 設置場所 */
            ECN_DEF_EPRP (#{objNAME}_CLASS_EOBJ, { 0x81, EPC_RULE_SET | EPC_RULE_GET | EPC_ANNOUNCE, 1, (intptr_t)&#{objname}_class_data.installation_location, (EPRP_SETTER *)ecn_data_prop_set, (EPRP_GETTER *)ecn_data_prop_get });\n
            /* 規格Ｖｅｒｓｉｏｎ情報 */
            ECN_DEF_EPRP (#{objNAME}_CLASS_EOBJ, { 0x82, EPC_RULE_GET, 4, (intptr_t)&#{objname}_class_data.standard_version_information, (EPRP_SETTER *)ecn_data_prop_set, (EPRP_GETTER *)ecn_data_prop_get });\n
            /* 異常発生状態 */
            ECN_DEF_EPRP (#{objNAME}_CLASS_EOBJ, { 0x88, EPC_RULE_GET | EPC_ANNOUNCE, 1, (intptr_t)&#{objname}_class_data.fault_status, (EPRP_SETTER *)alarm_prop_set, (EPRP_GETTER *)ecn_data_prop_get });\n
            /* メーカーコード */
            ECN_DEF_EPRP (#{objNAME}_CLASS_EOBJ, { 0x8A, EPC_RULE_GET, 3, (intptr_t)&#{objname}_class_data.manufacturer_code, (EPRP_SETTER *)ecn_data_prop_set, (EPRP_GETTER *)ecn_data_prop_get });

            ")

                val['elProperties'].each{|prop_id,val2| 
                    if val2['oneOf'] then
                    else
                        # val2['accessRule'].each{|rule_key,rule_value| #判断accessrule里面有哪个是required
                        #     if rule_value == "required" then
                        #         rule = Array.push(rule_key)
                        #     end
                        #     unless rule.size == 0 then # 如果存在reuqired，那么输出当前的属性信息
                        #     end

                        # rule里面必定存在get，因此可以先判断get是否是required，如果是那么继续解析data
                        # 最后再判断set是否是required
                        if val2['accessRule']['get'] == 'required' then
                            propName_jp = val2['propertyName']['ja']
                            propname_en = font_name(val2['propertyName']['en'])
                            cfg.puts ("/*#{propName_jp}*/")
                            if val2['accessRule']['set'] == 'required' then 
                                if val2['data']['$ref'] then
                                    ref = val2['data']['$ref'].sub( /#\/definitions\//, "" )
                                    val3 = Definitions[ref]
                                    if val3['type'] == 'state' then
                                        size = val3['size']
                                    elsif val3['type'] == 'raw' then
                                        size = val3['minSize']
                                    else size = 'NULL'
                                    end 
                                end   
                            cfg.puts ("ECN_DEF_EPRP(#{objNAME}_CLASS_EOBJ, {#{prop_id}, EPC_RULE_SET | EPC_RULE_GET, #{size}, (intptr_t)&#{objname}_class_data.#{propname_en}, (EPRP_SETTER *)#{propname_en}_prop_set, (EPRP_GETTER *)ecn_data_prop_get });\n
                            ")
                            else
                                if val2['data']['$ref'] then
                                    ref = val2['data']['$ref'].sub( /#\/definitions\//, "" )
                                    val3 = Definitions[ref]
                                    if val3['type'] == 'state' then
                                        size = val3['size']
                                    elsif val3['type'] == 'raw' then
                                        size = val3['minSize']
                                    else size = 'NULL'
                                    end 
                                end
                            cfg.puts ("ECN_DEF_EPRP(#{objNAME}_CLASS_EOBJ, {#{prop_id}, EPC_RULE_GET, #{size}, (intptr_t)&#{objname}_class_data.#{propname_en}, (EPRP_GETTER *)ecn_data_prop_get });\n
                            ")
                            end
                        end
                    end
                }
                cfg.close
            end
        }
    end

    def self.cfg_gen
        dev = ARGV
        Devices.each{ |id, val|
            # [1] classNameを持っていく　フォルダーを作る
            if val['oneOf'] then
                val['oneOf'].each{|val2|
                    if dev.empty? then
                        folder_gen(val2)
                    else
                        folder_gen_argv(val2, dev)
                    end        }
            elsif val['className'] == nil then
                #print "*** #{id} has no class name ***\n"
            elsif val['className']['en'] then   
                if dev.empty? then
                    folder_gen(val)
                else
                    folder_gen_argv(val, dev)
                end        #print( "#{val['className']['en']} = #{id}\n" )
            elsif val['className']['ja'] then
                #print( "#{val['className']['ja']} = #{id}\n" )
            else
                #print "### #{id} has class name but has neither 'ja' nor 'en' ***\n"
            end
        }
    end
end

Cfg_gen.cfg_gen

# tempfileの使い方：https://keruuweb.com/ruby-tempfile%E3%81%AE%E4%BD%BF%E3%81%84%E6%96%B9/
#     t = Tempfile.open
#     t.unlink #オブジェクトを削除する
# ブロックで表す場合：
# Tempfile.open{ |t|
#     t.method 
# }