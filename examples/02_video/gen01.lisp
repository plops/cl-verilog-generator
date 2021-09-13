(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload "cl-verilog-generator")
  (ql:quickload "cl-tcl-generator")
  (ql:quickload "alexandria"))


(in-package :cl-tcl-generator)

(progn
  (defparameter *path* "/home/martin/stage/cl-verilog-generator/examples/02_video")
  (write-source
   (format nil "~a/source/dk_video.sdc" *path*)
   `(do0
     ;; clocks in timing constraints
     ,@(loop for (name period n fn) in
	     `((I_clk 37.037 18.518 get_ports)
	       (serial_clk 2.694 1.347 get_nets)
	       (pix_clk 13.468 6.734 get_nets))
	     collect
	     `(create_clock :name ,name
			    :period ,period
			    :waveform (quote 0 ,n)
			    :add (bracket (,fn (quote ,name)))))
     ))
  (write-source
   ;; pin cconstraints
   (format nil "~a/source/dk_video.cst" *path*)
   `(do0
     ,@(loop for e in `((O_tmds_clk_p      ((comma 28 27))  ("PULL_MODE=NONE" "DRIVE=3.5"))
			("O_tmds_data_p[0]" ((comma 30 29))  ("PULL_MODE=NONE" "DRIVE=3.5"))
			("O_tmds_data_p[1]" ((comma 32 31))  ("PULL_MODE=NONE" "DRIVE=3.5"))
			("O_tmds_data_p[2]" ((comma 35 34))  ("PULL_MODE=NONE" "DRIVE=3.5"))
			("XCLK"            (33)             ("IO_TYPE=LVCMOS25" "PULL_MODE=NONE" "DRIVE=8"))
			("O_led[0]"        (10)             ("IO_TYPE=LVCMOS33" "PULL_MODE=NONE" "DRIVE=8"))
			(SCL        (44)             ("IO_TYPE=LVCMOS33" "PULL_MODE=NONE" "DRIVE=8"))
			(SDA        (46)             ("IO_TYPE=LVCMOS33" "PULL_MODE=NONE" "DRIVE=8"))
			(PIXCLK        (41)             ("IO_TYPE=LVCMOS33" "PULL_MODE=UP"))
			(HREF        (42)             ("IO_TYPE=LVCMOS33" "PULL_MODE=UP"))
			(VSYNC        (43)             ("IO_TYPE=LVCMOS33" "PULL_MODE=UP"))
			(I_rst_n        (14)             ("PULL_MODE=UP")) ;; why not lvcmos33?
			(I_clk        (45)             ("IO_TYPE=LVCMOS33" "PULL_MODE=UP"))
			,@(loop for (f g) in `((9 40)
					    (8 39)
					    (7 23)
					    (6 16)
					    (5 18)
					    (4 20)
					    (3 19)
					    (2 17)
					    (1 21)
					    (0 22))
				collect
				`(,(format nil "PIXDATA[~a]" f)        (,g)             ("PULL_MODE=UP")))
			)
	     collect
	     (destructuring-bind (name location-args port-args) e
	       `(semi
		(IO_LOC (string ,name)
			,@location-args)
		(IO_PORT (string ,name)
			 ,@port-args))))
     ))
  )


(in-package :cl-verilog-generator)

;; device: GW1NSR-LV4CQN48PC6/I5
;; GW1NSR-LV4CQN48PC6/I5
;; cp ~/stage/cl-verilog-generator/examples/02_video/source/*.{v,cst,sdc,ipc} /home/martin/gowin_fpga/b2/IDE/bin/fpga_project_xam/src

(progn
  (defparameter *path* "/home/martin/stage/cl-verilog-generator/examples/02_video")
  (defparameter *day-names*
    '("Monday" "Tuesday" "Wednesday"
      "Thursday" "Friday" "Saturday"
      "Sunday"))
  ;; https://github.com/sipeed/TangNano-4K-example/blob/main/dk_video/project/src/ov2640/I2C_Interface.v
  ;; http://www4.cs.umanitoba.ca/~jacky/Teaching/Courses/74.795-LocalVision/ReadingList/ov-sccb.pdf

  ;; instantiate ip cores
  (let ((device 'gw1nsr4c-009)
	(fabric-clk 159))
   (loop for e in `((GW_PLLVR
		     (CLKOUTD false)
		     (CLKOUT_FREQ ,fabric-clk)
		     (DYNAMIC true)
		     (CLKOUT_TOLERANCE 0))
		   
		    (TMDS_PLLVR
		     (CLKOUTD true)
		     (CLKOUTD_BYPASS false)
		     (CLKOUTD_FREQ 12.5)
		     (CLKOUTD_SOURCE_CLKOUT true)
		     (CLKOUTD_TOLERANCE 3)
		     (CLKOUT_FREQ 371.25)
		     (DYNAMIC false)
		     (CLKOUT_TOLERANCE 1)
		     ))
	 do
	    (destructuring-bind (ipc-name &rest clauses) e
	      (write-ipc
	       (format nil "~a/source/~a.ipc"  *path* ipc-name)
	       `((General
		  (ipc_version 4)
		  (file ,ipc-name)
		  (module ,ipc-name)
		  (target_device ,device)
		  (type clock_pllvr)
		  (version 1.0))
		 (Config
		  (CKLOUTD3 false)
		  (CLKFB_SOURCE 0)
		  (CLKIN_FREQ 27)
		  ,@clauses
		  (CLKOUTP false)
		  (CLKOUT_BYPASS false)
		  (CLKOUT_DIVIDE_DYN true)
		  (LANG 0)
		  (LOCK_EN true)
		  (MODE_GENERAL true)
		  (PLL_PWD false)
		  (PLL_REGULATOR false)
		  (RESET_PLL false))))))

    (let ((name "hyperram_memory_interface"))
      (write-ipc
       (format nil "~a/source/~a.ipc"  *path* name)
       `((General
	  (ipc_version 4)
	  (file ,name)
	  (module HyperRAM_Memory_Interface_Top)
	  (target_device ,device)
	  (type hyperram_emb)
	  (version 1.0))
	 (Config
	  (BURST_MODE 128)
	  (CLK_TYPE DIFF)
	  (DEEP_POWER_DOWN OFF)
	  (DISABLE_IO true)
	  (DQ_WIDTH 8)
	  (DRIVE_STRENGTH 34)
	  (HYBRID_SLEEP_MODE OFF)
	  (INITIAL_LATENCY 6)
	  (LANG 0)
	  (MEMORY_CLK ,fabric-clk)
	  (MEMORY_TYPE W956x8MKY)
	  (PASR full)
	  (PSRAM_WIDTH 8)
	  (REFRESH_RATE normal)
	  (SIMULATION false)
	  (Synthesis_tool GowinSynthesis)
	  ))))
    (let ((name "dvi_tx"))
      (write-ipc
       (format nil "~a/source/~a.ipc"  *path* name)
       `((General
	  (ipc_version 4)
	  (file ,name)
	  (module DVI_TX_Top)
	  (target_device ,device)
	  (type ,name)
	  (version 1.0))
	 (Config
	  (DISABLE_IO_INSERTION true)
	  (ELVDS false)
	  (LANG 0)
	  (RX_CLOCK_IN_FREQUENCY 40) ;; i guess this from the external clock. is it generated by the tv?
	  (Synthesis_tool GowinSynthesis)
	  (TLVDS true)
	  (USING_EXTERNAL_CLOCK true)))))
    (let ((name "video_frame_buffer"))
      (write-ipc
       (format nil "~a/source/~a.ipc"  *path* name)
       `((General
	  (ipc_version 4)
	  (file ,name)
	  (module Video_Frame_Buffer_Top)
	  (target_device ,device)
	  (type ,name)
	  (version 1.0))
	 (Config
	  (Addr_Width 22)
	  (Data_Width 32)
	  (Disable_IO_Insertion true)
	  (Image_Size 00100000)
	  (LANG 0)
	  (Memory_Type HyperRAM)
	  (Read_Burst_Length 128)
	  (Read_FIFO_Burst_Mult 8)
	  (Read_FIFO_Depth 1024)
	  (Read_Video_Width 16)
	  (Synthesis_tool GowinSynthesis)
	  (User_Three_Frame_Buffer true)
	  (Write_Burst_Length 128)
	  (Write_FIFO_Depth 1024)
	  (Write_Video_Width 16)))))

    
    (write-source
     (format nil "~a/source/i2c_interface.v" *path*)
     `(module i2c_interface
	      ("input clk"		;; 50MHz
	       "inout siod"		;; SCCB data signal
	       "output sioc"		;; SCCB clock signal
	       "output taken" ;; flag to go to next address of LUT
	       "input send" ;; flag to indicate if configuration has finished
	       "input [7:0] rega" ;; register address
	       "input [7:0] value" ;; data to write into register address
	       )
	      ,@(loop for e in `((divider 7 "8'b00000001")
				 (busy_sr 31 "{32{1'b0}}")
				 (data_sr 31 "{32{1'b1}}")
				 (sioc_temp)
				 (taken_temp)
				 (siod_temp))
		      collect
		      (destructuring-bind (name &optional size default) e
			(format nil "reg ~@[[~a:0]~] ~a~@[ =~a~];" size name default)))
	      ,@(loop for e in `(siod sioc taken)
		      collect
		      `(assign ,e ,(format nil "~a_temp" e)))
	      (always-at (or busy_sr (aref data_sr 31))
			 ;; tristate when idle or siod driven by master
			 (if (logior
			      (== (aref busy_sr (slice 11 10))
				  "2'b10")
			      (== (aref busy_sr (slice 20 19))
				  "2'b10")
			      (== (aref busy_sr (slice 29 28))
				  "2'b10"))
			     (setf siod_temp "1'bZ")
			     (setf siod_temp (aref data_sr 31))))
	      (always-at
	       "posedge clk"
	       (setf taken_temp "1'b0")
	       (if (== (aref busy_sr 31)
		       0)
		   (do0
		    (setf sioc_temp 1)
		    (if (== send 1)
			(if (== divider "8'b0000_0000")
			    (setf data_sr (concat "3'b100"
						  "8'h42" ; id
						  "1'b0"
						  rega
						  "1'b0"
						  value
						  "1'b0"
						  "2'b01")
				  busy_sr (concat "3'b111"
						  "9'b1_1111_1111"
						  "9'b1_1111_1111"
						  "9'b1_1111_1111"
						  "2'b11")
				  taken_temp "1'b1")
			    (incf divider))
			)
		    (do0
		     (case (concat (aref busy_sr (slice 31 29))
				   (aref busy_sr (slice 2 0)))
		       ,@(loop for e in `(("6'b111_111" 1 1 1 1)
					  ("6'b111_110" 1 1 1 1)
					  ("6'b111_100" 0 0 0 0)
					  ("6'b110_000" 0 1 1 1)
					  ("6'b100_000" 1 1 1 1)
					  ("6'b000_000" 1 1 1 1)
					  (t 0 1 1 0)
					  )
			       
			       collect
			       (destructuring-bind (top-key a b c d) e
				 `(,top-key
				   (case (aref divider (slice 7 6))
				     ,@(loop for key in `("2'b00" "2'b01" "2'b10" t)
					     and f in (list a b c d)
					     collect
					     `(,key (setf sioc_temp ,f))))))))

		     
		     (if (== divider "8'b1111_1111")
			 (setf busy_sr (concat (aref busy_sr (slice 30 0))
					       "1'b0")
			       data_sr (concat (aref data_sr (slice 30 0))
					       "1'b1")
			       divider "{8{1'b0}}"
			       )
			 (incf divider)))))))))
  (write-source
   (format nil "~a/source/syn_gen.v" *path*)
   `(module syn_gen
	    (,@(loop for e in `((pxl_clk)
				(rst_n)
				(h_total :len 16)
				(h_sync :len 16)
				(h_bporch :len 16)
				(h_res :len 16)
				(v_total :len 16)
				(v_sync :len 16)
				(v_bporch :len 16)
				(v_res :len 16)
				(rd_hres :len 16)
				(rd_vres :len 16)
				(hs_pol ) ;; 0 .. negative polarity
				(vs_pol )
				(rden :type "output reg")
				(de :type "output reg")
				(hs :type "output reg")
				(vs :type "output reg"))
		     collect
		     (destructuring-bind (name &key (type "input") len) e
		       (format nil "~a~@[ [~a:0]~] ~a_~a" type (when len (- len 1))
			       (if (string= type "input")
				   "I"
				   "O")
			       name)))
	     )
	  ,@(loop for e in `((V_cnt 15)
			     (H_cnt 15)
			     (Rden_dn)
			     )
		  collect
		  (destructuring-bind (name &optional size default) e
		    (format nil "reg ~@[[~a:0]~] ~a~@[ =~a~];" size name default)))
	  ,@(loop for e in `(de_w hs_w vs_w)
		  collect
		  (format nil "wire Pout_~a;" e))
	  ,@(loop for e in `(de_dn hs_dn vs_dn)
		  collect
		  (format nil "reg Pout_~a;" e))
	  ,@(loop for e in `(Rden_w)
		  collect
		  (format nil "wire ~a;" e))
	
	  #+nil ,@(loop for e in `(siod sioc taken)
		  collect
		  `(assign ,e ,(format nil "~a_temp" e)))
	  (always-at (or "posedge I_pxl_clk"
			   "negedge I_rst_n")
		       ;; tristate when idle or siod driven by master
		       (if !I_rst_n
			   (setf V_cnt "16'd0")
			   (cond ((logand (<= (- I_v_total "1'b1") V_cnt)
					  (<= (- I_h_total "1'b1") H_cnt))
				  (setf V_cnt "16'd0"))
				 ((<= (- I_h_total "1'b1")
				      H_cnt)
				  (incf V_cnt "1'b1"))
				 (t
				  (setf V_cnt V_cnt))
				 )))
	  (always-at (or "posedge I_pxl_clk"
			 "negedge I_rst_n") 
		     (cond (!I_rst_n
			    (setf H_cnt "16'd0"))
			   ((<= (- I_h_total "1'b1")
				H_cnt)
			    (setf H_cnt "16'd0"))
			   (t
			    (incf H_cnt "1'b1")))
		     )
	  (assign Pout_de_w (and ,@(loop for dir in `(H V)
			   collect
			   (let* ((sdir (string-downcase dir))
				  (cnt (format nil "~a_cnt" dir))
				  (sync (format nil "I_~a_sync" sdir))
				  (bporch (format nil "I_~a_bporch" sdir))
				  (res (format nil "I_~a_res" sdir)))
			     `(and (<= (+ ,sync ,bporch)
				     ,cnt)
				 (<= ,cnt
				     (- (+ ,sync
					 ,bporch
					 ,res
					 )
					"1'b1"))))))
		  #+nil (and (and (<= (+ I_h_sync I_h_bporch)
					  H_cnt)
				      (<= H_cnt
					  (- (+ I_h_sync I_h_bporch I_h_res )
					     "1'b1")))
				 (and (<= (+ I_v_sync I_v_bporch)
					  V_cnt)
				      (<= V_cnt
					  (- (+ I_v_sync I_v_bporch I_v_res )
					     "1'b1")))))
	  (assign Pout_hs_w (~ (and (<= "16'd0"
					H_cnt)
				    (<= H_cnt (- I_h_sync "1'b1"))))
		  )
	  (assign Pout_vs_w (~ (and (<= "16'd0"
					V_cnt)
				    (<= V_cnt (- I_v_sync "1'b1"))))
		  )
	  (assign Rden_w
		  (and ,@(loop for dir in `(H V)
			   collect
			   (let* ((sdir (string-downcase dir))
				  (cnt (format nil "~a_cnt" dir))
				  (sync (format nil "I_~a_sync" sdir))
				  (bporch (format nil "I_~a_bporch" sdir))
				  (res (format nil "I_rd_~ares" sdir)))
			     `(and (<= (+ ,sync ,bporch)
				     ,cnt)
				 (<= ,cnt
				     (- (+ ,sync
					 ,bporch
					 ,res
					 )
					"1'b1")))))))
	  (always-at (or "posedge I_pxl_clk"
			 "negedge I_rst_n")
		     (if !I_rst_n
			 (setf ,@(loop for (e f) in `((Pout_de 0) ( Pout_hs 1) (Pout_vs 1) (Rden 0))
				       appending
				       `(,(format nil "~a_dn" e)
					 ,(format nil "1'b~a" f))))
			 (setf ,@(loop for e in `(Pout_de Pout_hs Pout_vs Rden)
				       appending
				       `(,(format nil "~a_dn" e)
					 ,(format nil "~a_w" e))))
			 
			 ))
	  (always-at (or "posedge I_pxl_clk"
			 "negedge I_rst_n")
		     (if !I_rst_n
			 (setf ,@(loop for (e f) in `((O_de 0)
						      (O_hs 1)
						      (O_vs 1)
						      (O_rden 0))
				       appending
				       `(,(format nil "~a" e)
					 ,(format nil "1'b~a" f))))
			 (setf O_de Pout_de_dn
			       O_hs (? I_hs_pol (~ Pout_hs_dn) Pout_hs_dn)
			       O_hs (? I_vs_pol (~ Pout_vs_dn) Pout_vs_dn)
			       O_rden Rden_dn)
			 
			 ))
	    ))

  ;; https://www.uctronics.com/download/cam_module/OV2640DS.pdf v.1.6
  ;; http://www.uctronics.com/download/OV2640_DS.pdf v.2.2
  (write-source
   (format nil "~a/source/ov2640_registers.v" *path*)
   `(module ov2640_registers
	    ("input clk"		
	     "input resend"
	     "input advance"
	     "output [15:0] command" 
	     "output finished")
	    ,@(loop for e in `((sreg 15)
			       (finished_temp)
			       (address 8 "{9{1'b0}}")
			       )
		    collect
		    (destructuring-bind (name &optional size default) e
		      (format nil "reg ~@[[~a:0]~] ~a~@[ =~a~];" size name default)))
	    (assign command sreg
		    finished finished_temp)
	    (always-at sreg
		       ;; when register and value is FFFF indicate config is finished
		       (if (== sreg "16'hFFFF")
			   (setf finished_temp 1)
			   (setf finished_temp 0)))
	    (always-at
	     "posedge clk"
	     (cond ((== resend 1)
		    (setf address "{8{1'b0}}"))
		   ((== advance 1)
		    (incf address)))
	     
	     ,(let ((l  `((FF 01) (12 80)
			  (FF 00) (2c ff) (2e df)
			  (FF 01) (3c 32) (11 80) ;/* Set PCLK divider */
			  (09 02)	;/* Output drive x2 */
			  (04 28) (13 E5) (14 48) (15 00) ;//Invert VSYNC
			  (2c 0c) (33 78) (3a 33) (3b fb) (3e 00) (43 11) (16 10) (39 02) (35 88) (22 0a) (37 40) (23 00)
			  (34 a0) (06 02) (06 88) (07 c0) (0d b7) (0e 01) (4c 00) (4a 81) (21 99) (24 40) (25 38) (26 82) ;/* AGC/AEC fast mode operating region */	
			  (48 00)	;/* Zoom control 2 MSBs */
			  (49 00)	;/* Zoom control 8 MSBs */
			  (5c 00) (63 00) (46 00) (47 00) (0C 3A) ;/* Set banding filter */
			  (5D 55) (5E 7d) (5F 7d) (60 55) (61 70) (62 80) (7c 05) (20 80) (28 30) (6c 00) (6d 80) (6e 00)
			  (70 02) (71 94) (73 c1) (3d 34) (5a 57) (4F bb) (50 9c)
			  (FF 00) (e5 7f) (F9 C0) (41 24) (E0 14) (76 ff) (33 a0) (42 20) (43 18) (4c 00) (87 D0) (88 3f) (d7 03) (d9 10) (D3 82) (c8 08) (c9 80)
			  (7C 00) (7D 00) (7C 03) (7D 48) (7D 48) (7C 08) (7D 20) (7D 10) (7D 0e)
			  (90 00) (91 0e) (91 1a) (91 31) (91 5a) (91 69) (91 75) (91 7e) (91 88) (91 8f) (91 96) (91 a3) (91 af) (91 c4) (91 d7) (91 e8) (91 20)
			  (92 00) (93 06) (93 e3) (93 03) (93 03) (93 00) (93 02) (93 00) (93 00) (93 00) (93 00) (93 00) (93 00) (93 00) (96 00)
			  (97 08) (97 19) (97 02) (97 0c) (97 24) (97 30) (97 28) (97 26) (97 02) (97 98) (97 80) (97 00) (97 00)
			  (a4 00) (a8 00) (c5 11) (c6 51) (bf 80) (c7 10) (b6 66) (b8 A5) (b7 64) (b9 7C) (b3 af) (b4 97) (b5 FF) (b0 C5) (b1 94) (b2 0f) (c4 5c) (a6 00)
			  (a7 20) (a7 d8) (a7 1b) (a7 31) (a7 00) (a7 18) (a7 20) (a7 d8) (a7 19) (a7 31) (a7 00) (a7 18) (a7 20) (a7 d8) (a7 19) (a7 31) (a7 00) (a7 18)
			  (7f 00) (e5 1f) (e1 77) (dd 7f) (C2 0E)
			  (FF 01) (FF 00) (E0 04) (DA 04) ;//08:RGB565  04:RAW10
			  (D7 03) (E1 77) (E0 00)
			  (FF 00) (05 01) (5A A0) ;//(w>>2)&0xFF	//28:w=160 //A0:w=640 //C8:w=800
			  (5B 78) ;//(h>>2)&0xFF	//1E:h=120 //78:h=480 //96:h=600
			  (5C 00) ;//((h>>8)&0x04)|((w>>10)&0x03)		
			  (FF 01) (11 80) ;//clkrc=0x83 for resolution <= SVGA		
			  (FF 01) (12 40) ;/* DSP input image resoultion and window size control */
			  (03 0A) ;/* UXGA=0x0F, SVGA=0x0A, CIF=0x06 */
			  (32 09) ;/* UXGA=0x36, SVGA/CIF=0x09 */
			  (17 11) ;/* UXGA=0x11, SVGA/CIF=0x11 */
			  (18 43) ;/* UXGA=0x75, SVGA/CIF=0x43 */
			  (19 00) ;/* UXGA=0x01, SVGA/CIF=0x00 */
			  (1A 4b) ;/* UXGA=0x97, SVGA/CIF=0x4b */
			  (3d 38) ;/* UXGA=0x34, SVGA/CIF=0x38 */
			  (35 da) (22 1a) (37 c3) (34 c0) (06 88) (0d 87) (0e 41) (42 03) (FF 00) ;/* Set DSP input image size and offset. The sensor output image can be scaled with OUTW/OUTH */
			  (05 01) (E0 04) (C0 64) ;/* Image Horizontal Size 0x51[10:3] */  //11 0010 0000 = 800
			  (C1 4B) ;/* Image Vertiacl Size 0x52[10:3] */    //10 0101 1000 = 600   
			  (8C 00) ;/* {0x51[11], 0x51[2:0], 0x52[2:0]} */
			  (53 00) ;/* OFFSET X[7:0] */
			  (54 00) ;/* OFFSET Y[7:0] */
			  (51 C8) ;/* H SIZE[7:0]= 0x51/4 */ //200
			  (52 96) ;/* V SIZE[7:0]= 0x52/4 */ //150       
			  (55 00) ;/* V SIZE[8]/OFFSET Y[10:8]/H SIZE[8]/OFFSET X[10:8] */
			  (57 00) ;/* H SIZE[9] */
			  (86 3D) (50 80) ;/* H DIVIDER/V DIVIDER */        
			  (D3 80)	   ;/* DVP prescalar */
			  (05 00) (E0 00) (FF 00) (05 00)
			  (FF 00) (E0 04) (DA 04) ;//08:RGB565  04:RAW10
			  (D7 03) (E1 77) (E0 00)    
			  )
			))
		`(case address
		   ,@(loop for (e f) in l
			   and i from 0
			   collect
			   `(,(format nil "~3,'0d" i)
			     (setf sreg ,(format nil "16'h~a_~a" e f))))
		   (t (setf sreg "16'hFF_FF"))
		   )))))
  (write-source
   (format nil "~a/source/ov2640_controller.v" *path*)
   `(module ov2640_controller
	    ("input clk"		
	     "input resend"
	     "output config_finished"
	     "output sioc"
	     "inout siod"
	     "output reset"
	     "output pwdn")
	    ,@(loop for e in `((command 15)
			       (finished)
			       (taken)
			       )
		    collect
		    (destructuring-bind (name &optional size default) e
		      (format nil "wire ~@[[~a:0]~] ~a~@[ =~a~];" size name default)))
	    ,@(loop for e in `((send :default 0)
			       
			       )
		    collect
		    (destructuring-bind (name &key size default) e
		      (format nil "reg ~@[[~a:0]~] ~a~@[ =~a~];" size name default)))
	    (assign config_finished finished
		    reset 1
		    pwdn 0)
	    (always-at finished
		       (assign= send ~finished))
	    (make-instance ov2640_registers
			   (lut :clk clk
				:advance taken
				:command command
				:finished finished
				:resend resend))
	    (make-instance i2c_interface
			   (i2c
			    :clk clk
			    :taken taken
			    :siod siod
			    :sioc sioc
			    :send send
			    :rega (aref command (slice 15 8))
			    :value (aref command (slice 7 0)))
			   )
	    ))
  (write-source
   (format nil "~a/source/testpattern.v" *path*)
   `(module testpattern
		       
		       ( ,@(loop for e in `(pxl_clk
						       rst_n
						       (mode 2)
						       (single_r 7)
						       (single_g 7)
						       (single_b 7)
						       (h_total 11)
						       (h_sync 11)
						       (h_bporch 11)
						       (h_res 11)
						       (v_total 11)
						       (v_sync 11)
						       (v_bporch 11)
						       (v_res 11)
						       hs_pol
						       vs_pol
						       )
					    collect
					    (format nil "input ~a"
						    (if (listp e)
							(format nil "[~a:0] I_~a" (second e) (first e))
							e)))
			          ,@(loop for e in `(O_de
							   "reg O_hs"
							   "reg O_vs"
							   (O_data_r 7)
							   (O_data_g 7)
							   (O_data_b 7))
						collect
						(format nil "output ~a"
							(if (listp e)
							    (format nil "[~a:0] ~a" (second e) (first e))
							    e))))
		         "localparam N=5;"
		       ;; bgr
		          ,@(loop for (name b g r) in `((white 1 1 1)
							     (yellow 0 1 1)
							     (cyan 1 1 0)
							     (green 0 1 0)
							     (magenta 1 0 1)
							     (red 0 0 1)
							     (blue 1 0 0)
							     (black 0 0 0))
				       collect
				       (format nil "localparam ~a = {{~{8'd~a~^,~}}};"
					       (string-upcase (format nil "~a" name))
					       (list (* 255 b)
						     (* 255 g)
						     (* 255 r))))

		           ,@(loop for e in `((Pout_de_w)
						   (Pout_hs_w)
						   (Pout_vs_w)
						   (De_pos)
						   (De_neg)
						   (Vs_pos)
						   (Net_pos :size 1)
						   (Single_color :size 23
								 )
						   (Data_sel :size 23))
					collect
					(destructuring-bind (name &key size default) e
					  (format nil "wire ~@[[~a:0]~] ~a~@[ =~a~];" size name default)))
		           ,@(loop for e in `((V_cnt :size 11)
						   (H_cnt :size 11)
						   (Pout_de_dn :size N-1)
						   (Pout_hs_dn :size N-1)
						   (Pout_vs_dn :size N-1)
						   (De_vcnt :size 11)
						   (De_hcnt :size 11)
						   (De_hcnt_d1 :size 11)
						   (De_hcnt_d2 :size 11)
						   ;; color bar
						   (Color_trig_num :size 11)
						   (Color_trig)
						   (Color_cnt :size 3)
						   (Color_bar :size 23)
						   ;; net grid
						   (Net_h_trig)
						   (Net_v_trig)
						   
						   (Net_grid :size 23)
						   ;; gray
						   (Gray :size 23)
						   (Gray_d1 :size 23)
						   (Data_tmp :size 23)
						   
						   )
					collect
					(destructuring-bind (name &key size default) e
					  (format nil "reg ~@[[~a:0]~] ~a~@[ =~a~];" size name default)))
		        (do0 (always-at
				   (or "posedge I_pxl_clk"
				       "negedge I_rst_n")
				   ;; generate hs, vs and de signals
				   (if !I_rst_n
				       (setf V_cnt "12'd0")
				       (cond ((&& (<= (- I_v_total "1'b1")
						      V_cnt)
						  (<= (- I_h_total "1'b1")
						      H_cnt))
					      (setf V_cnt "12'd0")
					      )
					     ((<= (- I_h_total "1'b1")
						  H_cnt)
					      (incf V_cnt "1'b1"))
					     (t (setf V_cnt V_cnt)))))

				  (always-at
				   (or "posedge I_pxl_clk"
				       "negedge I_rst_n")
				   
				   (cond (!I_rst_n
					  (setf H_cnt "12'd0")
					  
					  )
					 ((<= (- I_h_total "1'b1")
					      H_cnt)
					  (setf H_cnt "12'd0")
					  )
					 (t (incf H_cnt "1'b1")))
				   ))
		        (do0
			      (assign Pout_de_w (and ,@(loop for dir in `(H V)
							     collect
							     (let* ((sdir (string-downcase dir))
								    (cnt (format nil "~a_cnt" dir))
								    (sync (format nil "I_~a_sync" sdir))
								    (bporch (format nil "I_~a_bporch" sdir))
								    (res (format nil "I_~a_res" sdir)))
							       `(and (<= (+ ,sync ,bporch)
									 ,cnt)
								     (<= ,cnt
									 (- (+ ,sync
									       ,bporch
									       ,res
									       )
									    "1'b1")))))))
			      (assign Pout_hs_w (~ (and (<= "12'd0"
							    H_cnt)
							(<= H_cnt (- I_h_sync "1'b1"))))
				      )
			      (assign Pout_vs_w (~ (and (<= "12'd0"
							    V_cnt)
							(<= V_cnt (- I_v_sync "1'b1"))))
				      )
			      
			      (always-at
			       (or "posedge I_pxl_clk"
				   "negedge I_rst_n")
			       
			       (cond ((!I_rst_n)
				      (setf Pout_de_dn "{N{1'b0}}"
					    Pout_hs_dn "{N{1'b1}}"
					    Pout_vs_dn "{N{1'b1}}"))
				     (t (setf Pout_de_dn (concat (aref Pout_de_dn (slice (-N 2) 0))
								 Pout_de_w)
					      Pout_hs_dn (concat (aref Pout_hs_dn (slice (-N 2) 0))
								 Pout_hs_w)
					      Pout_vs_dn (concat (aref Pout_vs_dn (slice (-N 2) 0))
								 Pout_vs_w)
					      )))
			       ))
		        (do0 
			      ;; consider data alignment
			      (assign O_de (aref Pout_de_dn 4))

			      (always-at
			       (or "posedge I_pxl_clk"
				   "negedge I_rst_n")
			       
			       (cond ((!I_rst_n)
				      (setf O_hs "1'b1"
					    O_vs "1'b1"))
				     (t (setf O_hs (? I_hs_pol
						      (aref ~Pout_hs_dn 3)
						      (aref Pout_hs_dn 3))
					      O_vs (? I_vs_pol
						      (aref ~Pout_vs_dn 3)
						      (aref Pout_vs_dn 3))
					      )))
			       ))
		        (do0
			      ;; test pattern
			      ;; rising edge of de
			      (assign De_pos (& (aref !Pout_de_dn 1)
						(aref Pout_de_dn 0)))
			      (assign Vs_pos (& (aref !Pout_vs_dn 1)
						(aref Pout_vs_dn 0)))
			      (assign De_neg (& (aref Pout_de_dn 1)
						(aref !Pout_de_dn 0)))

			      (always-at
			       (or "posedge I_pxl_clk"
				   "negedge I_rst_n")
			       (cond ((!I_rst_n)
				      (setf De_hcnt "12'd0"))
				     ((== De_pos "1'b1")
				      (setf De_hcnt "12'd0"))
				     ((== (aref Pout_de_dn 1) "1'b1")
				      (incf De_hcnt "1'b1"))
				     (t
				      (setf De_hcnt De_hcnt))))

			      (always-at
			       (or "posedge I_pxl_clk"
				   "negedge I_rst_n")
			       (cond ((!I_rst_n)
				      (setf De_vcnt "12'd0"))
				     ((== Vs_pos "1'b1")
				      (setf De_vcnt "12'd0"))
				     ((== De_neg "1'b1")
				      (incf De_vcnt "1'b1"))
				     (t
				      (setf De_vcnt De_vcnt)))))
		       
		       (do0 ;; color bar
			(always-at
			 (or "posedge I_pxl_clk"
			     "negedge I_rst_n")
			 (cond ((!I_rst_n)
				(setf Color_trig_num  "12'd0"))
			       ((== (aref Pout_de_dn 1) "1'b1")
				(setf Color_trig_num  (aref I_h_res (slice 11 3))))
			       ((&& (== Color_trig "1'b1")
				    (== (aref Pout_de_dn 1) "1'b1"))
				(incf Color_trig_num (aref I_h_res (slice 11 3))))
			       (t
				(setf Color_trig_num
				      Color_trig_num))))
			(always-at
			 (or "posedge I_pxl_clk"
			     "negedge I_rst_n")
			 (cond ((!I_rst_n)
				(setf Color_trig "1'd0"))
			       ((== De_hcnt (- Color_trig_num "1'b1"))
				(setf Color_trig "1'b1"))
			       (t
				(setf Color_trig "1'b0"))))
			(always-at
			 (or "posedge I_pxl_clk"
			     "negedge I_rst_n")
			 (cond ((!I_rst_n)
				(setf Color_cnt "3'd0"))
			       ((== (aref Pout_de_dn 1) "1'b0")
				(setf Color_cnt "3'b0"))
			       ((&& (== Color_trig "1'b1")
				    (== (aref Pout_de_dn 1)
					"1'b1"))
				(incf Color_cnt "1'b1"))
			       (t
				(setf Color_cnt Color_cnt))))
			(always-at
			 (or "posedge I_pxl_clk"
			     "negedge I_rst_n")
			 (cond ((!I_rst_n)
				(setf Color_bar "24'd0"))
			       ((== (aref Pout_de_dn 2) "1'b1")
				(case Color_cnt
				  ,@(loop for e in `(WHITE
						     YELLOW
						     CYAN
						     GREEN
						     MAGENTA
						     RED
						     BLUE
						     BLACK
						     )
					  and ei from 0
					  collect
					  `(,(format nil "3'd~a" ei)
					    (setf Color_bar ,e)))
				  (t (setf Color_bar BLACK))))
			       (t
				 (setf Color_bar BLACK))))
		
			)))
  
  (write-source
   (format nil "~a/source/video_top.v" *path*)
   `(module video_top
	    ("input I_clk"		
	     "input I_rst_n"
	     "output [1:0] O_led"
	     "inout SDA"
	     "inout SCL"
	     ,@(loop for e in `(VSYNC
				HREF
				(PIXDATA 9)
				PIXCLK
				)
		     collect
		     (format nil "input ~a"
			     (if (listp e)
				 (format nil "[~a:0] ~a" (second e) (first e))
				 e)))
	     ,@(loop for e in `(XCLK
				(O_hpram_ck 0)
				(O_hpram_ck_n 0)
				(O_hpram_cs_n 0)
				(O_hpram_reset_n 0)
				O_tmds_clk_p
				O_tmds_clk_n
				(O_tmds_data_p 2)
				(O_tmds_data_n 2)
				)
		     collect
		     (format nil "output ~a"
			     (if (listp e)
				 (format nil "[~a:0] ~a" (second e) (first e))
				 e)))
	     ,@(loop for e in `((IO_hpram_dq 7)
				(IO_hpram_rwds 0))
		     collect
		     (format nil "inout ~a"
			     (if (listp e)
				 (format nil "[~a:0] ~a" (second e) (first e))
				 e)))
	     )
	    
	    ,@(loop for e in `((running)
					;(tp0_vs_in)
					;(tp0_hs_in)
					;(tp0_de_in)
			       #+nil ,@(loop for e in `(r g b)
					     collect
					     `(,(format nil "tp0_data_~a" e) :size 7 ))
			       (cam_data :size 15)
			       ,@(loop for e in `(re vs hs)
				       collect
				       `(,(format nil "syn_off0_~a" e)))
			       (off0_syn_de)
			       (off0_syn_data :size 15)
			       (dma_clk)
			       (memory_clk)
			       (mem_pll_lock)
			       (cmd)
			       (cmd_en)
			       (addr :size 21)
			       (wr_data :size 31)
			       (data_mask :size 3)
			       (rd_data_valid)
			       (rd_data :size 31)
			       (init_calib)
			       ,@(loop for e in `(re vs hs)
				       collect
				       `(,(format nil "rgb_~a" e)))
			       (rgb_data :size 23)
			       ;; hdmi
			       (serial_clk)
			       (pll_lock)
			       (hdmi_rst_n)
			       (pix_clk)
			       (clk_12M)
			       
			       )
		    collect
		    (destructuring-bind (name &key size default) e
		      (format nil "wire ~@[[~a:0]~] ~a~@[ =~a~];" size name default)))
	    ,@(loop for e in `((run_cnt :size 31
					)
			       (vs_r)
			       (cnt_vs :size 9)
			       (pixdata_dl :size 9)
			       (hcnt)
			       
			       )
		    collect
		    (destructuring-bind (name &key size default) e
		      (format nil "reg ~@[[~a:0]~] ~a~@[ =~a~];" size name default)))

	    (always-at (or "posedge I_clk"
			   "negedge I_rst_n")
		       (cond (!I_rst_n
			      (setf run_cnt "32'd0"))
			     ((<= "32'd27_000_000"
				  run_cnt)
			      (setf run_cnt "32'd0"))
			     (t
			      (incf run_cnt "1'b1"))
			     )
					;(assign= send ~finished)
		       )
	    (assign running (? (< run_cnt
				  "32'd13_500_000")
			       "1'b1"
			       "1'b0")
		    (aref O_led 0) running
		    (aref O_led 1) ~init_calib
		    XCLK clk_12M)
	    (always-at (or "posedge I_clk"
			   "negedge I_rst_n")
		       (cond (!I_rst_n
			      (setf cnt_vs 0))
			     ((== cnt_vs "10'h3ff")
			      (setf cnt_vs cnt_vs))
			     (vs_r ;; tp0_vs_in
			      (incf cnt_vs))
			     (t
			      (setf cnt_vs cnt_vs))))
	    
	    (make-instance ov2640_controller
			   (u_ov2640_controller
			    :clk clk_12M
			    :resend "1'b0"
			    :config_finished ""
			    :sioc SCL
			    :siod SDA
			    :reset ""
			    :pwdn ""))
	    (always-at (or "posedge PIXCLK"
			   "negedge I_rst_n")
		       (cond (!I_rst_n
			      (setf pixdata_dl "10'd0"))
			     (t
			      (setf pixdata_dl PIXDATA))))
	    (always-at (or "posedge PIXCLK"
			   "negedge I_rst_n")
		       (cond (!I_rst_n
			      (setf hcnt "1'd0"))
			     (HREF
			      (setf hcnt ~hcnt))
			     (t
			      (setf hcnt "1'd0"))))
	    (assign cam_data
		    (concat (aref PIXDATA (slice 9 5))
			    (aref PIXDATA (slice 9 4))
			    (aref PIXDATA (slice 9 5))))
	    #+nil 
	    ,@(loop for (e f g) in `((clk I_clk PIXCLK)
				     (vs ~tp0_vs_in VSYNC) de data))
	    ,@(loop for (e f) in `((clk PIXCLK)
				   (vs VSYNC)
				   (de HREF)
				   (data cam_data))
		    collect
		    `(assign ,(format nil "ch0_vfb_~a_in" e)
			     ,f))
	    (make-instance Video_Frame_Buffer_Top
			   (Video_Frame_Buffer_Top_inst
			    :I_rst_n init_calib
			    :I_dma_clk dma_clk
			    :I_wr_halt "1'd0"
			    :I_rd_halt "1'd0"
			    ;; video data input
			    ,@(loop for e in `((clk)
					       (vs_n vs)
					       (de)
					       (data))
				    appending
				    (destructuring-bind (lhs &optional (rhs lhs)) e
				      `(,(make-keyword (format nil "I_vin0_~a" lhs))
					,(format nil "ch0_vfb_~a_in" rhs))))
			    :O_vin0_fifo_full ""
			    ;; video data output
			    :I_vout0_clk pix_clk
			    :I_vout0_vs_n ~syn_off0_vs
			    :I_vout0_de syn_off0_re
			    :O_vout0_den off0_syn_de
			    :O_vout0_data off0_syn_data
			    :O_vout0_fifo_empty ""
			    ;; ddr write request
			    ,@(loop for e in `((cmd)
					       (cmd_en)
					       (addr)
					       (wr_data)
					       (data_mask))
				    appending
				    (destructuring-bind (lhs &optional (rhs lhs)) e
				      `(,(make-keyword (format nil "O_~a" lhs))
					,(format nil "~a" rhs))))
			    ,@(loop for e in `((rd_data_valid)
					       (rd_data)
					       (init_calib)
					       )
				    appending
				    (destructuring-bind (lhs &optional (rhs lhs)) e
				      `(,(make-keyword (format nil "I_~a" lhs))
					,(format nil "~a" rhs))))
			    ))
	    (make-instance GW_PLLVR
			   (GW_PLLVR_inst
			    :clkout memory_clk
			    :lock mem_pll_lock
			    :clkin I_clk))
	    (make-instance HyperRAM_Memory_Interface_Top
			   (HyperRAM_Memory_Interface_Top_inst
			    :clk I_clk
			    :memory_clk memory_clk
			    :pll_lock mem_pll_lock
			    :rst_n I_rst_n
			    :O_hpram_ck O_hpram_ck
			    :O_hpram_ck_n O_hpram_ck_n
			    :IO_hpram_rwds IO_hpram_rwds
			    :IO_hpram_dq IO_hpram_dq
			    :O_hpram_reset_n O_hpram_reset_n
			    :O_hpram_cs_n O_hpram_cs_n
			    :wr_data wr_data
			    :rd_data rd_data
			    :rd_data_valid rd_data_valid
			    :addr addr
			    :cmd cmd
			    :cmd_en cmd_en
			    :clk_out dma_clk
			    :data_mask data_mask
			    :init_calib init_calib))
	    (make-instance syn_gen
			   (syn_gen_inst
			    :I_pxl_clk pix_clk
			    :I_rst_n hdmi_rst_n
			    ,@(loop for (lhs rhs) in `((h_total 1650)
						       (h_sync 40)
						       (h_bporch 220)
						       (h_res 1280)
						       (v_total 750)
						       (v_sync 5)
						       (v_bporch 20)
						       (v_res 720)
						       (rd_hres 640)
						       (rd_vres 480)
						       )
				    appending
				    `(,(make-keyword (format nil "I_~a" lhs))
				      ,(format nil "16'd~a" rhs)))
			    :I_hs_pol "1'b1"
			    :I_vs_pol "1'b1"
			    :O_rden syn_off0_re
			    :O_de out_de
			    :O_hs syn_off0_hs
			    :O_vs syn_off0_vs
			    ))
	    "localparam N=5; // delay N clocks"
	    ,@(loop for e in `((Pout_hs_dn "N-1")
			       (Pout_vs_dn "N-1")
			       (Pout_de_dn "N-1")
			       )
		    collect
		    (destructuring-bind (name &optional size default) e
		      (format nil "reg ~@[[~a:0]~] ~a~@[ =~a~];" size name default)))
	    (always-at (or "posedge pix_clk"
			   "negedge hdmi_rst_n")
		       (if !hdmi_rst_n
			   (setf Pout_hs_dn "{N{1'b1}}"
				 Pout_vs_dn "{N{1'b1}}"
				 Pout_de_dn "{N{1'b0}}")
			   (setf Pout_hs_dn (concat (aref Pout_hs_dn (slice (- N 2) 0))
						    syn_off0_hs)
				 Pout_vs_dn (concat (aref Pout_vs_dn (slice (- N 2) 0))
						    syn_off0_vs)
				 Pout_de_dn (concat (aref Pout_de_dn (slice (- N 2) 0))
						    out_de))))
	    ;; TMDS TX
	    (assign rgb_data (? off0_syn_de
				(concat (aref off0_syn_data (slice 15 11))
					(aref off0_syn_data (slice 10 5))
					"2'd0"
					(aref off0_syn_data (slice 4 0)
					      )
					"3'd0")
				"24'h1fff00" ;; r g b
				)
		    rgb_vs (aref Pout_vs_dn 4)
		    rgb_hs (aref Pout_hs_dn 4)
		    rgb_de (aref Pout_de_dn 4))
	    (make-instance TMDS_PLLVR
			   (TMDS_PLLVR_inst
			    :clkin I_clk
			    :clkout serial_clk
			    :clkoutd clk_12M
			    :lock pll_lock
			    ))
	    (assign hdmi_rst_n (and I_rst_n pll_lock))
	    (make-instance CLKDIV
			   (u_clkdiv
			    :RESETN hdmi_rst_n
			    :HCLKIN serial_clk ;; 5x
			    :CLKOUT pix_clk ;; 1x
			    :CALIB "1'b1"
			    ))
	    "defparam u_clkdiv.DIV_MODE=\"5\";"
	    (make-instance DVI_TX_Top
			   (DVI_TX_Top_inst
			    :I_rst_n hdmi_rst_n
			    :I_serial_clk serial_clk
			    :I_rgb_clk pix_clk
			    :I_rgb_vs rgb_vs
			    :I_rgb_hs rgb_hs
			    :I_rgb_de rgb_de
			    :I_rgb_r (aref rgb_data (slice 23 16))
			    :I_rgb_g (aref rgb_data (slice 15 8))
			    :I_rgb_b (aref rgb_data (slice 7 0))
			    :O_tmds_clk_p O_tmds_clk_p
			    :O_tmds_clk_n O_tmds_clk_n
			    :O_tmds_data_p O_tmds_data_p
			    :O_tmds_data_n O_tmds_data_n))
	    )))
