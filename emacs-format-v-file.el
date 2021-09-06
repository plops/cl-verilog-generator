;; https://cslab.pepperdine.edu/warford/BatchIndentationEmacs.html
(defun emacs-format-function ()
   "Format the whole buffer."
   (indent-region (point-min) (point-max) nil)
   (untabify (point-min) (point-max))
   (save-buffer)
)
