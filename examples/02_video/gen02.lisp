(defpackage :cl-ov2640
  (:use :cl)
  )
(in-package :cl-ov2640)

;; register parser for ov2640 camera

(let
    ((l
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
						    (1 sensor)))))))))
