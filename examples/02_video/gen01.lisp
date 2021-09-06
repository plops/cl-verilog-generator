(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload "cl-verilog-generator")
  (ql:quickload "alexandria"))

(in-package :cl-verilog-generator)

(progn
  (defparameter *path* "/home/martin/stage/cl-verilog-generator/examples/02_video")
  (defparameter *day-names*
    '("Monday" "Tuesday" "Wednesday"
      "Thursday" "Friday" "Saturday"
      "Sunday"))
  ;; https://github.com/sipeed/TangNano-4K-example/blob/main/dk_video/project/src/ov2640/I2C_Interface.v
  ;; http://www4.cs.umanitoba.ca/~jacky/Teaching/Courses/74.795-LocalVision/ReadingList/ov-sccb.pdf
  (write-source
   (format nil "~a/source/i2c_interface.v" *path*)
   `(module i2c_interface
	    ("input clk"		;; 50MHz
	     "input siod"		;; SCCB data signal
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
						 id
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
			    (incf divider))))))))

  ;; https://www.uctronics.com/download/cam_module/OV2640DS.pdf v.1.6
  ;; http://www.uctronics.com/download/OV2640_DS.pdf v.2.2
  (write-source
   (format nil "~a/source/ov2640_registers.v" *path*)
   `(module ov2640_interface
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
	     #+nil (case address
	       ()))))
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
	    (make-instance (i2c_interface
			    :clk clk
			    :taken taken
			    :siod siod
			    :sioc sioc
			    :send send
			    :rega (aref command (slice 15 8))
			    :value (aref command (slice 7 0)))
			   )
	    )))
