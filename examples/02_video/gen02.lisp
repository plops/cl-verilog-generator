(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload "cl-py-generator")
  (ql:quickload "alexandria"))
(in-package :cl-py-generator)

;; register parser for ov2640 camera


(progn
  (defparameter *path* "/home/martin/stage/cl-verilog-generator/examples/02_video")
  (defparameter *code-file* "run_02_ov2640_register")
  (defparameter *source* (format nil "~a/source/" *path*))
  (defparameter *day-names*
    '("Monday" "Tuesday" "Wednesday"
      "Thursday" "Friday" "Saturday"
      "Sunday"))
  (defun lprint (cmd &optional rest)
    `(when debug
       (print (dot (string ,(format nil "{} ~a ~{~a={}~^ ~}" cmd rest))
		   (format (- (time.time) start_time)
			   ,@rest)))))
  (let* ((l-dsp
	   `((0 rsvd)
	     (5 r-bypass 1 rw (((7 1) rsvd)
			       ((0) bypass-dsp-select ((0 dsp) (1 bypass)))))
	     (6 rsvd)
	     (44 qs 0c rw quantization-scale-factor)
	     (45 rsvd)
	     (50 ctrli 0 rw (((7) lp-dp)
			     ((6) round)
			     ((5 3) v-divider)
			     ((2 0) h-divider)))
	     (51 hsize 40 rw (((7 0) (aref h-size (slice 7 0)) :type real/4)))
	     (52 vsize f0 rw (((7 0) (aref v-size (slice 7 0)) :type real/4)))
	     (53 xoffl 0 rw (((7 0) (aref offset-x (slice 7 0)))))
	     (54 yoffl 0 rw (((7 0) (aref offset-y (slice 7 0)))))
	     (55 vhyx 8 rw (((7) (aref v-size 8))
			    ((6 4) (aref offset-y (slice 10 8)))
			    ((3) (aref h-size 8))
			    ((2 0) (aref offset-x (slice 10 8)))))
	     (56 dprp 0 rw (((7 4) dp-sely)
			    ((3 0) dp-selx)))
	     (57 test 0 rw (((7) (aref h-size 9))
			    ((6 0) rsvd)))
	     (5a zmow 58 rw (((7 0) (aref outw (slice 7 0)) :type real/4)))
	     (5b zmoh 48 rw (((7 0) (aref outh (slice 7 0)) :type real/4)))
	     (5c zmhh 0 rw (((7 4) zoom-speed)
			    ((2) (aref outh 8))
			    ((1 0) (aref outw (slice 9 8)))))
	     (5d rsvd)
	     (7c bpaddr 0 rw (((7 0) sde-address)))
	     (7d bpdata 0 rw (((7 0) sde-data)))
	     (7e rsvd)
	     (86 ctrl2 0d rw (((7 6) rsvd)
			      ((5) dcw)
			      ((4) sde)
			      ((3) uv-adj)
			      ((2) uv-avg)
			      ((1) rsvd)
			      ((0) cmx)))
	     (87 ctrl3 50 rw (((7) bpc)
			      ((6) wpc)
			      ((5 0) rsvd)))
	     (88 rsvd)
	     (8c sizel 0 rw (((7) rsvd)
			     ((6) (aref hsize 11)) ;; fixme
			     ((5 3) (aref hsize (slice 2 0)))
			     ((2 0) (aref vsize (slice 2 0)))))
	     (8d srvd)
	     (c0 hsize8 80 rw ((7 0) (aref hsize 10 3)))
	     (c1 vsize8 60 rw ((7 0) (aref vsize 10 3)))
	     (c2 ctrl0 0c rw (,@(loop for e in `(aec-en aec-sel stat-sel vfirst yuv422 yuv-en rgb-en raw-en)
				      and ei from 7 downto 0
				      collect
				      `((,ei) ,e))))
	     (c3 ctrl1 ff rw (,@(loop for e in `(cip dmy raw-gma dg awb awb-gain lenc pre)
				      and ei from 7 downto 0
				      collect
				      `((,ei) ,e))))
	     (c4 rsvd)
	     (d3 r-dvp-sp 82 rw (((7) auto-mode)
				 ((6 0) dvp-output-speed-control ) ;; sysclk
				 ))
	     (d4 rsvd)
	     (da image-mode 0 rw (((7) rsvd)
				  ((6) y8-dvd-en)
				  ((5) rsvd)
				  ((4) jpeg-en ((0 non-compressed)
						(1 jpeg)))
				  ((3 2) dvp-output ((00 yuv422-dvp)
						     (01 raw10-dvp)
						     (10 rgb565-dvp)
						     (11 rsvd)))
				  ((1) href-timing-sel ((0 href-same-as-sensor)
							(1 href-is-vsync)))
				  ((0) byte-swap-enable ((0 yuyv)
							 (1 uyvy)))))
	     (db rsvd)
	     (e0 reset 4 rw (,@(loop for e in `(rsvd microcontroller sccb jpeg rsvd dvp ipu cif)
				     and ei from 7 downto 0
				     collect
				     `((,ei) ,e))))
	     (e1 rsvd)
	     (ed reged 1f rw (((7 5) rsvd)
			      ((4) clock-output-power ((0 output-hold-last-state-upon-power-down)
						       (1 output-tri-state-upon-power-down)))))
	     (ee rsvd)
	     (f0 ms-sp 4 rw (((7 0) sccb-master-speed)))
	     (f1 rsvd)
	     (f7 ss-id 60 rw (((7 0) sccb-slave-id)))
	     (f8 ss-ctrl 1 rw (,@(loop for e in `(rsvd rsvd address-auto-increase-en rsvd
						       sccb-en delay-sccb-master-clock sccb-master-access-en
						       sensor-pass-through-access-en)
				       and ei from 7 downto 0
				       collect
				       `((,ei) ,e))))
	     (f9 mc-bist 40 rw (,@(loop for e in `(mcu-reset
						   boot-rom-sel
						   rw-1-err-12k
						   rw-0-err-12k
						   rw-1-err-512
						   rw-0-err-512
						   bist-busy-bit ;; read: busy bit, write: one-shot reset of mcu
						   launch-bist)
					and ei from 7 downto 0
					collect
					`((,ei) ,e))))
	     (fa mc-al 0 rw (((7 0) program-mem-address-lo)))
	     (fb mc-ah 0 rw (((7 0) program-mem-address-hi)))
	     (fc mc-d 80 rw (((7 0) program-mem-address-boundary)))
	     (fd p-cmd 0 rw (((7 0) sccb-proto-cmd-reg)))
	     (fe p-status 0 rw (((7 0) sccb-proto-status-reg)))
	     (ff ra-dlmt 7f rw (((7 1) rsvd)
				((0) register-bank-sel ((0 dsp)
							(1 sensor)))))))
	 (l-sensor
	   `((0 gain 0 rw (((7 0) gain)))
	     (1 rsvd)
	     (3 com1 0f rw (((7 6) dummy-frame ((00 rsvd) ;; 0f uxga, 0a svga, 06 cif
							  (01 allow-1-dummy)
							  (10 allow-3-dummy)
							  (11 allow-7-dummy)))
			    ((5 4) rsvd)
			    ((3 2) (aref win-end-line-ctrl-v (slice 1 0)))
			    ((1 0) (aref win-start-line-ctrl-v (slice 1 0)))))
	     (4 reg4 20 rw (,@(loop for e in `(h-mirror
					       v-flip
					       (aref vref 0)
					       (aref href 0)
					       rsvd)
				    and ei from 7 downto 2
				    collect
				    `((,ei) ,e))
			    ((1 0) (aref aec (slice 1 0)))))
	     (5 rsvd)
	     (8 reg8 40 rw (((7 0) frame-exp-pre-charge-row)))
	     (9 com2 0 rw (((7 5) rsvd)
			   ((4) standby-mode-en ((0 normal)
						 (1 standby)))
			   ((3) rsvd)
			   ((2) pin-pwdn-resetb-as-slvs)
			   ((1 0) output-drive-sel ((00 1x)
						    (01 3x)
						    (10 2x)
						    (11 4x)))))
	     (a pidh 26 ro (((7 0) (aref product-id (slice 15 8)))))
	     (b pidl 41 ro (((7 0) (aref product-id (slice 7 0)))))
	     (c com3 38 rw (((7 3) rsvd)
			    ((2) banding-manual ((0 60hz)
						 (1 50hz)))
			    ((1) banding-auto)
			    ((0) snaphot ((0 live-after-snapshot)
					  (1 single-frame-only)))))
	     (d rsvd)
	     (10 aec 33 rw (((7 0) (aref aec (slice 9 2)))))
	     (11 clkrc 0 rw (((7) internal-freq-double ((0 off)
							(1 on)))
			     ((6) rsvd)
			     ((5 0) clk-divider)))
	     (12 com7 0 rw (((7) srst)
			    ((6 4) resolution-sel ((000 uxga)
						   (010 cif)
						   (100 svga)))
			    ((3 ) rsvd)
			    ((2) zoom)
			    ((1) color-bar-test ((0 off)
						 (1 on)))
			    ((0) rsvd)))
	     (13 com8 c7 rw (((7 6) rsvd)
			     ((5) banding-filter-sel ((0 off)
						  ;; setting on will use min exposure 1/120s
						      (1 on)))
			     ((4 3) rsvd)
			     ((2) agc-ctrl ((0 manual)
					    (1 auto)))
			     ((1) rsvd)
			     ((0) exposure-ctrl ((0 manual)
						 (1 auto)))))
	     (14 com9 50 rw (((7 5) agc-gain-ceil ((000 2x)
						   (001 4x)
						   (010 8x)
						   (011 16x)
						   (100 32x)
						   (101 64x)
						   (110 128x)))
			     ((4 0) rsvd)))
	     (15 com10 0 rw (;; if bypass dsp is selected
			     ((7 6) rsvd)
			     ((5) pclk-sel ((0 pclk-always)
					    (1 pclk-qualified-by-href)))
			     ((4) pclk-edge-sel ((0 falling)
						 (1 rising)))
			     ((3) href-polarity ((0 positive)
						 (1 negative)))
			     ((2) rsvd)
			     ((1) vsync-polarity ((0 positive)
						  (1 negative)))
			     ((0) rsvd)))
	     (16 rsvd)
	     (17 hrefst 11 rw (((7 0) (aref h-win-start (slice 10 3)) )))
	     (18 hrefend 75 ;; 75 uxga, 43 svga or cif
		 rw (((7 0) (aref h-win-end (slice 10 3)))))
	     (19 vstrt 01 ;; 01 uxga, 00 svga or cif
		 rw (((7 0) (aref v-win-line-start (slice 9 2)) )))
	     (1a vend 97 rw (((7 0) (aref v-win-line-end (slice 9 2)) )))
	     (1b rsvd)
	     (1c midh 7f r (((7 0) (aref manufacturer-id (slice 15 8)))))
	     (1c midl a2 r (((7 0) (aref manufacturer-id (slice 7 0)))))
	     (1e rsvd)
	     (24 aew 78 rw (((7 0) aew)))
	     (25 aeb 68 rw (((7 0) aeb)))
	     (26 vv d4 rw (((7 4) large_step_threshold_hi)
			   ((3 0) large_step_threshold_lo)))
	     (27 rsvd)
	     (2a reg2a 0 rw (((7 4) (aref line-interval-adjust (slice 11 8)))
			     ((3 0) rsvd)))
	     (2b frarl 0 rw (((7 0) (aref line-interval-adjust (slice 7 0)))))
	     (2c rsvd)
	     (2d addvsl 0 rw (((7 0) (aref vsync-pulse-width (slice 7 0)))))
	     (2e addvsh 0 rw (((7 0) (aref vsync-pulse-width (slice 15 8)))))
	     (2f yavg 0 rw (((7 0) luminance-avg)))
	     (30 rsvd)
	     (32 reg32 36 ;; 36 uxga, 9 svga or cif
		 rw (((7 6) pixel-clock-divide ((00 no-effect)
						(01 no-effect)
						(10 divide-by-2)
						(11 divide-by-4)))
		     ((5 3) (aref h-win-end (slice 2 0)))
		     ((2 0) (aref h-win-start (slice 2 0))))
		 )
	     (33 rsvd)
	     (34 arcom2 20 rw (((7 3) rsvd)
			       ((2) zoom-win-h-start)
			       ((1 0) rsvd)))
	     (35 rsvd)
	     (45 reg45 0 rw (((7 6) (aref agc (slice 9 8)))
			     ((5 0) (aref aec (slice 15 10)))))
	     (46 fll 0 rw (((7 0) (aref frame-length-adjust (slice 7 0)))))
	     (47 flh 0 rw (((7 0) (aref frame-length-adjust (slice 15 8)))))
	     (48 com19 0 rw (((7 2) rsvd)
			     ((1 0) (aref zoom-mode-v-start (slice 1 0)))))
	     (49 zooms 0 rw (((7 0) (aref zoom-mode-v-start (slice 9 2)))))
	     (4a rsvd)
	     (4b com22 20 rw (((7 0) flash-light-ctrl)))
	     (4c rsvd)
	     (4e com25 0 rw (((7 6) (aref banding-50Hz-aec (slice 9 8)))
			     ((5 4) (aref banding-60Hz-aec (slice  9 8)))
			     ((3 0) rsvd)))
	     (4f bd50 ca rw (((7 0) (aref banding-50Hz-aec (slice 7 0)))))
	     (50 bd60 a8 rw (((7 0) (aref banding-60Hz-aec (slice 7 0)))))
	     (51 rsvd)
	     (5d reg5d 0 rw (((7 0) (aref avg-sel (slice 7 0)))))
	     (5e reg5e 0 rw (((7 0) (aref avg-sel (slice 15 8)))))
	     (5f reg5f 0 rw (((7 0) (aref avg-sel (slice 23 16)))))
	     (60 reg60 0 rw (((7 0) (aref avg-sel (slice 31 24)))))
	     (61 histo-lo 80 rw (((7 0) hist-lo)))
	     (62 histo-hi 90 rw (((7 0) hist-hi)))
	     (63 rsvd)))
	 
	 (code
	   `(do0
	     (do0
		  
	      (imports (matplotlib))
                                        ;(matplotlib.use (string "QT5Agg"))
					;"from matplotlib.backends.backend_qt5agg import (FigureCanvas, NavigationToolbar2QT as NavigationToolbar)"
					;"from matplotlib.figure import Figure"
	      (imports ((plt matplotlib.pyplot)
					;  (animation matplotlib.animation) 
					;(xrp xarray.plot)
			))
                  
	      (plt.ion)
					;(plt.ioff)
	      (setf font (dict ((string size) (string 5))))
	      (matplotlib.rc (string "font") **font)
	      )
	     (imports (			;os
					;sys
					;time
					;docopt
		       pathlib
					;(np numpy)
					;serial
		       (pd pandas)
					;(xr xarray)
					;(xrp xarray.plot)
					;skimage.restoration
					;(u astropy.units)
					; EP_SerialIO
					;scipy.ndimage
		       scipy.optimize
					;nfft
					;sklearn
					;sklearn.linear_model
					;itertools
					;datetime
		       (np numpy)
					; scipy.sparse
					;scipy.sparse.linalg
					; jax
					;jax.random
					;jax.config
					;copy
		       subprocess
		       threading
					;datetime
					;time
					; mss
					;cv2
		       time
					;edgar
		       tqdm
					;requests
					;xsdata
					;generated
					;  xbrl
		       ))
	     (imports (logging
		       ))
					;"from generated import *"
					;"from xsdata.formats.dataclass.parsers import XmlParser"
	     
	     
	     (setf
	      _code_git_version
	      (string ,(let ((str (with-output-to-string (s)
				    (sb-ext:run-program "/usr/bin/git" (list "rev-parse" "HEAD") :output s))))
			 (subseq str 0 (1- (length str)))))
	      _code_repository (string ,(format nil "https://github.com/plops/cl-py-generator/tree/master/example/56_myhdl/source/04_tang_lcd/run_04_lcd.py"))
	      _code_generation_time
	      (string ,(multiple-value-bind
			     (second minute hour date month year day-of-week dst-p tz)
			   (get-decoded-time)
			 (declare (ignorable dst-p))
			 (format nil "~2,'0d:~2,'0d:~2,'0d of ~a, ~d-~2,'0d-~2,'0d (GMT~@d)"
				 hour
				 minute
				 second
				 (nth day-of-week *day-names*)
				 year
				 month
				 date
				 (- tz)))))
	     (setf start_time (time.time)
		   debug True)


	     (do0
	      
	      #+nil
	      ((0 rsvd)
	       (5 r-bypass 1 rw (((7 1) rsvd)
				 ((0) bypass-dsp-select ((0 dsp) (1 bypass))))))
	     
	      ,(let ((names)
		     (addresses))
		 (loop for e in l-dsp
		       do
			  (destructuring-bind (address reg-name
					       &optional default permission
						 parts) e
			    (let ((address_ (read-from-string (format nil "#x~a" address)))
				  (default_ (when default
					      (read-from-string (format nil "#x~a" default)))))
			      (setf names (append names (list reg-name)))
			      (setf addresses (append addresses (list address_))))))
		 `(setf df (pd.DataFrame (dictionary :name (list ,@(mapcar #'(lambda (x)
									       `(string ,x))
									   names))
						     :address (list ,@addresses))
					 )))
	      ))
	   
	   ))
    (write-source (format nil "~a/~a" *source* *code-file*) code)
    ))

(append (list 1 2 3) (list 4))
