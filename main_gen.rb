#　アプリケーション.cを生成するため
require "json"
require "fileutils"
# Echonet Lite Device Description in JSON
class Main_gen
	devdesc_json_fname = "appendix_v3-1-6r5/EL_DeviceDescription_3_1_6r5.json"

	# Read Device Description (String)
	devdesc_json = File.read(devdesc_json_fname)

	# Convert JSON String to Hash
	DevDesc = JSON[devdesc_json]
	Devices = DevDesc["devices"]
	Definitions = DevDesc["definitions"]

	def self.parse_properties (val,className,fileName)
	    val.each{ |prop_id,val2|
	        if val2['oneOf'] then
	            
	        else
	            if val2['accessRule']['set'] == 'required' then
	                propertyName = val2['propertyName']['en']
					propertyName_JP = val2['propertyName']['ja']

	                if val2['data']['$ref'] then
		                ref = val2['data']['$ref'].sub( /#\/definitions\//, "" )
		                val3 = Definitions[ref]
		                parse_definitions(val3,propertyName,className,fileName)
	                elsif val2['data']['type'] == 'state' then
		                val3 = val2['data']
		                parse_definitions(val3,propertyName,className,fileName)
	                elsif val2['data']['oneOf'] then
		                val2['data']['oneOf'].each{ |val3|
	                    if val3['$ref'] then
		                    ref = val3['$ref'].sub( /#\/definitions\//, "" )
		                    val4 = Definitions[ref]
		                    parse_definitions(val4,propertyName,className,fileName)
	                    else
	                    end
	                }
	                else
	                end
	            else
	            end
	        end
	    }

	end

	def self.parse_definitions(val,propertyName,className,fileName)
	        if val['type'] == 'number' then
	            type = val['format']
	            propertyName = font_change(propertyName)
	            size = property_format_size(type)
	            min = val['minimum']
	            max = val['maximum']
	            print_function_number("  ",size,type,propertyName,className,min,max,fileName)
	        elsif val['type'] == 'state' then
	            size = val['size']
	            type = property_data_type(size)
	            propertyName = font_name(propertyName)
				signatureName = font_change(propertyName)
	            print_function_state("  ",size,type,propertyName,val,className,fileName,signatureName)
	        else

	        end
	end

	def self.property_data_type (size)
	    if size == 1 then
	        return 'uint8_t'
	    elsif size == 2 then
	        return 'uint16_t'
	    elsif size == 4 then
	        return 'uint32_t'
	    end
	end

	def self.property_format_size (type)
	    if type == 'uint8'
	        return 1
	    elsif type == 'uint16'
	        return 2
	    elsif type == 'uint32'
	        return 4
	    end
	end

	def self.print_function_state(indent,size,type,propertyName,val,className,fileName,signatureName)
	    fileName.print("int #{propertyName}_prop_set (const EPRPINIB *item, const void *src, int size, bool_t *anno)\n{\n
	    if(size != #{size})
	    #{indent}return 0;
	    *anno = *((#{type}*)item->exinf) != *((#{type}*)src);
	    switch (*(#{type}*)src) {\n")
	    print_state_type(indent + "    ", val,className,fileName,signatureName)
	    fileName.print("default:
	        return 0;
		}return 1;
	}
		
	")
	end

	def self.print_function_number(indent,size,type,propertyName,className,min,max,fileName)
	    fileName.print("int #{propertyName[0].downcase+propertyName[1..-1]}_prop_set (const EPRPINIB *item, const void *src, int size, bool_t *anno)\n{\n
	    if(size! = #{size})
	    #{indent}return 0;
	    if((*(#{type}_t*)src >= #{min}) && (*(#{type}_t*)src <= #{max})){
	        *((#{type}_t*)item->exinf) != *((#{type}_t*)src);
	        c#{className}_Set#{propertyName}( );
	    }
	    else{
	        return 0;
	    }return 1;
	}
		
	")
	end

	def self.print_state_type (indent,val,className,fileName,signatureName)
	    val['enum'].each{ |edt|
	        stateName = font_change(edt['state']['en'])
	        fileName.print("#{indent}case #{edt['edt']}: tECNL#{className}_c#{className}_set#{signatureName}_#{stateName}( );
	        break;\n")
	    }
		return val['enum'][0]["edt"]
	end

	def self.font_change(name)
	    # return name.split(/ |\_|\-/).map(&:capitalize).join(" ").gsub(/\s+/, '')
	    return name.gsub("/"," ").split(/ |\_|\-/).map(&:capitalize).join(" ").gsub(/\s+/, '')
	end

	def self.font_name(name)
	    return name.downcase.gsub(/\s+/,'_')
	end

	def self.file_output(val)
	    className = font_change(val['className']['en'])
		FileUtils.mkdir_p("lib/#{className}/src") # 建立多重路径
	    app = File.open("lib/#{className}/src/echonet_main.c","w+")
	    print_default_info(app,className)
	    objname = font_name(val['className']['en'])
	    app.puts("struct #{objname}_t #{objname}_class_data = {\n};")
		app.puts("struct node_profile_object_t local_node_data = {\n};")
	    parse_properties(val['elProperties'],className,app)
		print_default_functions(app,className)
	    app.close
	end

	def self.file_output_argv(val, dev)
	    className = font_change(val['className']['en'])
		dev.each{|arg|
		    if arg.gsub("\"","").chomp == val['className']['en'] then
			    FileUtils.mkdir_p("lib/#{className}/src") # 建立多重路径
			    app = File.open("lib/#{className}/src/echonet_main.c","w+")
			    print_default_info(app,className)
			    objname = font_name(val['className']['en'])
			    app.puts("struct #{objname}_t #{objname}_class_data = {\n};")
				app.puts("struct node_profile_object_t local_node_data = {\n};")
			    parse_properties(val['elProperties'],className,app)
				print_default_functions(app,className)
			    app.close
			end
		}
	end


	def self.print_default_info(fileName,className)
	    fileName.puts("#include <kernel.h>
	#include <t_syslog.h>
	#include <t_stdlib.h>
	#include <sil.h>
	#include <string.h>
	#include \"syssvc/serial.h\"
	#include \"syssvc/syslog.h\"
	#include \"kernel_cfg.h\"
	#include \"echonet_main.h\"
	#include \"echonet_cfg.h\"
	#include \"target_kernel_impl.h\"
	#include \"gpio_api.h\"
	#include \"rtc_api.h\"
	#include \"tECNL#{className}_tecsgen.h\"

	#define MAKER_CODE	0x00, 0x00, 0xB3

	static void main_initialize();
	static int main_get_timer();
	static void main_progress(int interval);
	static void main_recv_esv(T_EDATA *esv);
	static void main_break_wait(uint8_t *brkdat, int32_t len);
	static void main_timeout();

	void echonet_main_task(intptr_t exinf)
	{
		ER ret, ret2;
		SYSTIM prev, now;
		int timer;
		T_EDATA *esv;
		uint8_t brkdat[64];
		int32_t len;

		/* アプリケーションの初期化 */
		main_initialize();

		ret2 = get_tim(&now);
		if (ret2 != E_OK) {
			syslog(LOG_ERROR, \"get_tim\");
			return;
		}

		for (;;) {
			prev = now;

			/* タイマー取得 */
			timer = main_get_timer();

			/* 応答電文待ち */
			ret = ecn_trcv_esv(&esv, timer);
			if ((ret != E_OK) && (ret != E_BRK) && (ret != E_TMOUT)) {
				syslog(LOG_ERROR, \"ecn_trcv_esv\");
				break;
			}

			ret2 = get_tim(&now);
			if (ret2 != E_OK) {
				syslog(LOG_ERROR, \"get_tim\");
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
				if (ret != E_OK) {
					syslog(LOG_ERROR, \"ecn_rel_esv\");
					break;
				}
			}
			/* 応答電文待ちの割り込みの場合 */
			else if (ret == E_BRK) {
				/* 応答電文待ちの割り込みデータ取得 */
				ret = ecn_get_brk_dat(esv, brkdat, sizeof(brkdat), &len);
				if (ret != E_OK) {
					syslog(LOG_ERROR, \"ecn_get_brk_dat\");
					break;
				}

				/* 応答電文待ちの割り込み処理 */
				main_break_wait(brkdat, len);

				/* 領域解放 */
				ret = ecn_rel_esv(esv);
				if (ret != E_OK) {
					syslog(LOG_ERROR, \"ecn_rel_esv\");
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
	int main_timer = TMO_FEVR;
	enum main_state_t main_state = main_state_idle;

	static void main_initialize()
	{
		/* メインタスクを起動 */
		ER ret = act_tsk(MAIN_TASK);
		if (ret != E_OK) {
			syslog(LOG_ERROR, \"act_tsk\");
		}
	}

	static int main_get_timer()
	{
		return main_timer;
	}

	static void main_progress(int interval)
	{
		if(main_timer == TMO_FEVR)
			return;

		main_timer -= interval;
		if(main_timer < 0){
			main_timer = 0;
		}
	}

	static void main_recv_esv(T_EDATA *esv)
	{
		ER ret;
		ID eobjid;
		uint8_t epc;
		uint8_t pdc;
		uint8_t p_edt[256];
		T_ENUM_EPC enm;

		eobjid = ecn_get_eobj(esv);
		
		if (eobjid == EOBJ_NULL) {
			syslog(LOG_ERROR, \"ecn_get_eobj\");
		}

		ret = ecn_itr_ini(&enm, esv);
		if (ret != E_OK) {
			syslog(LOG_ERROR, \"ecn_itr_ini\");
			return;
		}

		for (;;) {
			while ((ret = ecn_itr_nxt(&enm, &epc, &pdc, p_edt)) == E_OK) {
				switch (epc) {
				case 0x80:
	                break;
				}
			}
			if (ret != E_BOVR) {
				syslog(LOG_ERROR, \"ecn_itr_nxt\");
				break;
			}
			if (enm.is_eof)
				break;
		}
	}

	static void main_break_wait(uint8_t *brkdat, int32_t len)
	{
		switch(main_state){
		case main_state_idle:
			break;
		}
	}

	static void main_timeout()
	{
		if(main_timer != 0)
			return;

		switch(main_state){
		case main_state_idle:
			break;
		}
	}

	")
	end

	def self.print_default_functions(fileName,className)
		fileName.puts("int onoff_prop_set(const EPRPINIB *item, const void *src, int size, bool_t *anno)
	{
		if(size != 1)
			return 0;
		*anno = *((uint8_t*)item->exinf) != *((uint8_t*)src);
		switch(*(uint8_t *)src){
		case 0x30: tECNL#{className}_c#{className}_setOperatingStatus_ON( );
			break;
		case 0x31: tECNL#{className}_c#{className}_setOperatingStatus_OFF( );
			break;
		default:
			return 0;
		}return 1;
	}

	int alarm_prop_set(const EPRPINIB *item, const void *src, int size, bool_t *anno)
	{
		ER ret;
		uint8_t data[1];
		if(size != 1)
			return 0;
		*anno = *((uint8_t *)item->exinf) != *((uint8_t *)src);
		switch(*(uint8_t *)src){
		case 0x41: tECNL#{className}_c#{className}_setFaultStatus_Fault( );
		case 0x42: tECNL#{className}_c#{className}_setFaultStatus_NoFault( );
			*((uint8_t *)item->exinf) = *((uint8_t *)src);
			break;
		default:
			return 0;
		}return 1;
	}
	")
	end

	# Dir.mkdir("src")
	def self.main_gen
		dev = ARGV
		Devices.each{ |id, val|
		    if val['oneOf'] then
		        # print( "#{id} oneOf\n" )
		        val['oneOf'].each{|val2|
		            # print( "  #{val2['className']['en']}\n" )
		            if dev.empty? then
		            	file_output(val2)
		            else
			            file_output_argv(val2, dev)
			        end
		        }
		    elsif val['className'] == nil then
		        #print "*** #{id} has no class name ***\n"
		    elsif val['className']['en'] then
		        if dev.empty? then
		        	file_output(val)
		        else
		            file_output_argv(val, dev)
		        end
		        #print( "#{val['className']['en']} = #{id}\n" )
		        #print_properties( val['elProperties'] )
		    elsif val['className']['ja'] then
		        #print( "#{val['className']['ja']} = #{id}\n" )
		        #print_properties( val['elProperties'] )
		    else
		        #print "### #{id} has class name but has neither 'ja' nor 'en' ***\n"
		    end
		}
	end
end

Main_gen.main_gen
	# propertyName[0].downcase+propertyName[1..-1] 首字母小写


