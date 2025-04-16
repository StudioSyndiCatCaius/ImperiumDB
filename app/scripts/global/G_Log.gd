extends Node



signal LogEvent(int,val)

func Notification(text: String, color: Color):
	print(text)
	LogEvent.emit(0,{
		_txt=text,_col=color
	})
	
