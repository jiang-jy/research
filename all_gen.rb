require "./main_gen"
require "./h_gen"
require "./cfg_gen"
require "./cdl_gen"
require "./callback_gen"

class All_gen
	def self.all_gen
		Main_gen.main_gen
		H_gen.h_gen
		Cfg_gen.cfg_gen
		Cdl_gen.cdl_gen
		Callback_gen.callback_gen
	end
end

All_gen.all_gen