# coding: utf-8
#
#  TECS Generator
#      Generator for TOPPERS Embedded Component System
#  
#   Copyright (C) 2008-2018 by TOPPERS Project
#--
#   上記著作権者は，以下の(1)～(4)の条件を満たす場合に限り，本ソフトウェ
#   ア（本ソフトウェアを改変したものを含む．以下同じ）を使用・複製・改
#   変・再配布（以下，利用と呼ぶ）することを無償で許諾する．
#   (1) 本ソフトウェアをソースコードの形で利用する場合には，上記の著作
#       権表示，この利用条件および下記の無保証規定が，そのままの形でソー
#       スコード中に含まれていること．
#   (2) 本ソフトウェアを，ライブラリ形式など，他のソフトウェア開発に使
#       用できる形で再配布する場合には，再配布に伴うドキュメント（利用
#       者マニュアルなど）に，上記の著作権表示，この利用条件および下記
#       の無保証規定を掲載すること．
#   (3) 本ソフトウェアを，機器に組み込むなど，他のソフトウェア開発に使
#       用できない形で再配布する場合には，次のいずれかの条件を満たすこ
#       と．
#     (a) 再配布に伴うドキュメント（利用者マニュアルなど）に，上記の著
#         作権表示，この利用条件および下記の無保証規定を掲載すること．
#     (b) 再配布の形態を，別に定める方法によって，TOPPERSプロジェクトに
#         報告すること．
#   (4) 本ソフトウェアの利用により直接的または間接的に生じるいかなる損
#       害からも，上記著作権者およびTOPPERSプロジェクトを免責すること．
#       また，本ソフトウェアのユーザまたはエンドユーザからのいかなる理
#       由に基づく請求からも，上記著作権者およびTOPPERSプロジェクトを
#       免責すること．
#  
#   本ソフトウェアは，無保証で提供されているものである．上記著作権者お
#   よびTOPPERSプロジェクトは，本ソフトウェアに関して，特定の使用目的
#   に対する適合性も含めて，いかなる保証も行わない．また，本ソフトウェ
#   アの利用により直接的または間接的に生じたいかなる損害に関しても，そ
#   の責任を負わない．
#  
#
#  $Id$
#++

#== celltype プラグインの共通の親クラス
class HRPKernelObjectPlugin < CelltypePlugin
    # @@obj_hash = {}

    #@celltype:: Celltype
    #@option:: String     :オプション文字列
    def initialize( celltype, option )
        super
        #
        #  それぞれのカーネルオブジェクトを解析対象セルタイプに追加
        #  目的：
        #   - カーネルオブジェクトのセルをメモリ保護対象外とする
        #    - カーネルオブジェクト本体の管理はTECSでなくOSで実施するため
        #   - カーネルオブジェクトのセルへのアクセスを直接関数呼出し
        #   　とする
        #    - システムサービス呼出しはOSが提供するため
        HRPKernelObjectPlugin.set_celltype(celltype)
    end
  
    #=== HRPKernelObjectPlugin#print_cfg_cre
    # 各種カーネルオブジェクトのCRE_*の出力
    # file:: FILE:     出力先ファイル
    # val :: string:   カーネルオブジェクトの属性の解析結果
    # tab :: string:   インデント用のtab
    def print_cfg_cre(file, cell, val, tab)
        raise "called virtual method print_cfg_cre in #{@celltype.get_name} plugin"
    end
  
    #=== HRPKernelObjectPlugin#print_cfg_sac
    # 各種カーネルオブジェクトのSAC_*の出力
    # file:: FILE:     出力先ファイル
    # val :: string:   カーネルオブジェクトの属性の解析結果
    # acv :: string:   アクセスベクタ
    def print_cfg_sac(file, val, acv)
        raise "called virtual method print_cfg_sac in #{@celltype.get_name} plugin"
    end
  
    #
    #  セルタイププラグインの本体メソッド
    #   - 静的APIの生成
    #  file:: FILE:     出力先ファイル
    #
    def gen_factory file
        dbgPrint "===== begin #{@celltype.get_name.to_s} plugin =====\n"

        #
        # 対象となるすべてのセルについて、受け口に結合されている
        # セルの所属ドメインを解析
        #  - 生成すべきcfgファイル名を取得するために必要
        #
        if !HRPKernelObjectPlugin.isChecked()
            HRPKernelObjectPlugin.check_referenced_cells()
        else
            dbgPrint "***** already checked\n"
        end

        # 追記するために AppFile を使う（文字コード変換されない）
        file2 = AppFile.open( "#{$gen}/tecsgen.cfg" )
        file2.print "\n/* Generated by #{self.class.name} */\n\n"

        @celltype.get_cell_list.each { |cell|
            if cell.is_generate?
                dbgPrint "===== begin check my domain #{cell.get_name} =====\n"
                #
                #  カーネルオブジェクトの属性を，valにコピー
                #
                val = {}
                @celltype.get_attribute_list.each{ |a|
                    # p a.get_name
                    if a.get_type.kind_of?( ArrayType )
                        val[a.get_name] = []
                        if j = cell.get_join_list.get_item(a.get_name)
                            # セル生成時に初期化する場合
                            j.get_rhs.each { |elem|
                                val[a.get_name] << elem.to_s
                            }
                        elsif i = a.get_initializer
                            # セルタイプの初期化値を使う場合
                            i.each { |elem|
                                val[a.get_name] << elem.to_s
                            }
                        else
                            raise "attribute is not initialized"
                        end
                    else
                        if j = cell.get_join_list.get_item(a.get_name)
                            # セル生成時に初期化する場合
                            val[a.get_name] = j.get_rhs.to_s
                        elsif i = a.get_initializer
                            # セルタイプの初期化値を使う場合
                            val[a.get_name] = i.to_s
                        else
                            raise "attribute is not initialized"
                        end
                    end
                }
                # generate.rbを参考に
                # $id$を置換
                if val[:id].nil? != true
                    name_array = @celltype.get_name_array( cell )
                    val[:id]   = @celltype.subst_name( val[:id], name_array )
                end
                # $cbp$の代わり
                cell_domain_root = cell.get_region.get_domain_root
                cell_domain_type = cell.get_region.get_domain_root.get_domain_type

                # CRE_XXX/DEF_XXXの生成
                if cell_domain_type.get_option.to_s != "OutOfDomain"
                    # 保護ドメインに属する場合
                    if !HRPKernelObjectPlugin.include_region(cell_domain_root.get_name.to_s)
                        # その保護ドメインの.cfgが生成されていない場合
                        HRPKernelObjectPlugin.set_region_list(cell_domain_root.get_name.to_s)
                        dbgPrint "~~~~~ #{cell_domain_root.get_name.to_s} is registered!\n"

#                        # if cell.get_region.get_param == :KERNEL_DOMAIN
#                        if cell_domain_type.get_option.to_s == "kernel"
#                            file2.print "KERNEL_DOMAIN{\n"
#                        else
#                            file2.print "DOMAIN(#{cell_domain_root.get_name.to_s}){\n"
#                        end
#                        file2.puts "\tINCLUDE(\"#{$gen}/tecsgen_#{cell_domain_root.get_name.to_s}.cfg\");" 
#                        file2.puts "}\n"
                    else
                        dbgPrint "~~~~~ #{cell.get_region.get_namespace_path} is included in"
                        #p @@region_list
                    end
                    file3 = AppFile.open( "#{$gen}/tecsgen_#{cell_domain_root.get_global_name}.cfg" )
                    print_cfg_cre(file3, cell, val,"")
                    file3.close
                else
                    # 無所属の場合
                    dbgPrint "~~~~~ #{cell_domain_root.get_namespace_path} is OutOfDomain\n"
                    # print "~~~~~ #{cell_domain_root.get_namespace_path} is OutOfDomain\n"
                    # p cell_domain_root.get_name
                    if cell_domain_root.get_name == "::" then
                      print_cfg_cre(file2, cell, val, "")
                    else
#                      if !HRPKernelObjectPlugin.include_region(cell_domain_root.get_name.to_s)
#                        # その保護ドメインの.cfgが生成されていない場合
#                        HRPKernelObjectPlugin.set_region_list(cell_domain_root.get_name.to_s)
#                        file2.puts "INCLUDE(\"#{$gen}/tecsgen_#{cell_domain_root.get_name.to_s}.cfg\");\n"
#                      end
                      file3 = AppFile.open( "#{$gen}/tecsgen_#{cell_domain_root.get_name.to_s}.cfg" )
                      print_cfg_cre(file3, cell, val,"")
                      file3.close
                    end

                end

                dbgPrint "===== end check my domain #{cell.get_name} =====\n"

                #
                # SAC_XXXの生成
                #
                if !val[:accessPattern1].nil?
                    dbgPrint "===== begin check regions #{cell.get_name} =====\n"
                    i = 0
                    acv = { \
                            :accessPattern1 => val[:accessPattern1], \
                            :accessPattern2 => val[:accessPattern2], \
                            :accessPattern3 => val[:accessPattern3], \
                            :accessPattern4 => val[:accessPattern4] \
                    }
                    acv_tmp = []
                    domain_roots = HRPPlugin.get_inter_domain_join_roots cell
                    # 結合先セルのドメインを加える
                    if cell_domain_type.get_kind != :OutOfDomain then
                      domain_roots << cell_domain_root
                    end
                    domain_roots.each{ |dr|
                      case dr.get_domain_type.get_kind
                      when :user
                        acv_tmp << "TACP(#{dr.get_name})"
                      when :kernel
                        acv_tmp << "TACP_KERNEL"
                      when :OutOfDomain
                        if cell_domain_type.get_kind == :OutOfDomain then
                          # 呼び元も、呼び先も OutOfDomain の場合
                          acv_tmp << "TACP_SHARED"
                        end
                      end
                    }
                    acv_tmp.uniq!
                    if acv_tmp.length == 0 then
                      # 呼び先セルが無所属かつ、呼び元も無所属のみ、または結合無しの場合
                      acv_tmp = [ "TACP_SHARED" ]
                    end
                    b_info = false
                    b_warn = false
                    acv.each { |key, acp|
                        if !acp.nil?
                            if acp != "OMIT"
                            elsif cell_domain_type.get_kind != :OutOfDomain
                              # p "UserDomainCell or KernelDomainCell"
                              domain_roots = HRPPlugin.get_inter_domain_join_roots cell
                              domain_roots.each{ |dr|
                                # 
                                case dr.get_domain_type.get_kind
                                when :kernel
                                when :user
                                  if dr.get_namespace_path != cell.get_region.get_domain_root.get_namespace_path
                                    # 他のユーザードメインからの結合
                                    if( b_warn == false ) then
                                      cdl_error( "HRP9999 '$1': kernel object joined from other user domain. kernel object joined from multi-user-domain must be placed out of domain", cell.get_name )
                                      b_warn = true
                                    end
                                  end
                                when :OutOfDomain
                                  if( b_info == false ) then
                                    # 無所属からの結合
                                    # cdl_error( "HRP9999 kernel object joined from out of domain" )
                                    if cell_domain_type.get_kind == :OutOfDomain
                                      # この情報は、不要と判断する (無所属から無所属へ結合があると、アクセス許可ベクタが設定されない)
                                      # cdl_info2( cell.get_locale, "HRP9999 '$1': kernel object joined from out of domain, access vector is not set", cell.get_name )
                                      b_info = true
                                    end
                                  end
                                else
                                  raise "unknown domain kind"
                                end
                              }
                              # acv[key] = "TACP(#{cell_domain_root.get_name.to_s})"
                            else
                              # p "OutOfDomainCell"
                              # 無所属のセル
                              # 結合元ドメインに許可する
                              # 結合元に無所属のセルがあると、TACP_SHARED が設定される. フロー解析してドメインを特定できるのが、あるべき仕様
                            end
                            if acp == "OMIT"
                              acv[key] = acv_tmp.join( '|' )
                            end 
                        end
                    }
                    #各種SACの生成
                    domainOption = cell_domain_type.get_option
                    # p "domain_root ", cell.get_region.get_domain_root.get_name
                    if domainOption != "OutOfDomain" || cell.get_region.get_domain_root.get_name != "::"
                        # 保護ドメインに属する場合
                        file3 = AppFile.open( "#{$gen}/tecsgen_#{cell.get_region.get_name.to_s}.cfg" )
                        print_cfg_sac(file3, val, acv)
                        file3.close
                    else
                        # 無所属の場合
                        print_cfg_sac(file2, val, acv)
                    end

                    dbgPrint "===== end check regions #{cell.get_name} =====\n"
                end
            end
        }
        dbgPrint "===== end #{@celltype.get_name.to_s} plugin =====\n"
        file2.close
    end

    # カーネルオブジェクトセルタイプの管理
    # HRPKernelObjectPluginクラスに対してメソッド呼出しを行うことを想定
    @@checked = false
    @@celltype_list = []
    @@region_list = []

    def self.isChecked()
        return @@checked
    end

    def self.check_referenced_cells()
        dbgPrint "===== begin check registered celltype =====\n"
        self.get_celltype_list.each { |ct|
          dbgPrint( ct.get_name.to_s + "\n" )
        }
        dbgPrint "===== end check registered celltype =====\n"

        @@checked = true
    end

    def self.set_celltype( celltype )
        @@celltype_list << celltype
    end

    def self.get_celltype_list
        return @@celltype_list
    end

    def self.set_region_list( region )
        @@region_list << region
    end

    def self.include_region( region )
        return @@region_list.include?(region)
    end

    def self.include_celltype?( celltype )
        return @@celltype_list.include?(celltype)
    end

end

