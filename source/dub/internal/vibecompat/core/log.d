/**
	Central logging facility for vibe.

	Copyright: © 2012 rejectedsoftware e.K.
	License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
	Authors: Sönke Ludwig
*/
module dub.internal.vibecompat.core.log;

import std.array;
import std.datetime;
import std.format;
import std.stdio;
import core.thread;

private {
	shared LogLevel s_minLevel = LogLevel.info;
	shared LogLevel s_logFileLevel;
}

/// Sets the minimum log level to be printed.
void setLogLevel(LogLevel level) nothrow
{
	s_minLevel = level;
}

LogLevel getLogLevel()
{
	return s_minLevel;
}

/**
	Logs a message.

	Params:
		level = The log level for the logged message
		fmt = See http://dlang.org/phobos/std_format.html#format-string
*/
void logDebug(string file=__FILE__, int line=__LINE__, T...)(string fmt, lazy T args) nothrow { log2(file, line, LogLevel.debug_, fmt, args); }
/// ditto
void logDiagnostic(string file=__FILE__, int line=__LINE__, T...)(string fmt, lazy T args) nothrow { log2(file, line, LogLevel.diagnostic, fmt, args); }
/// ditto
void logInfo(string file=__FILE__, int line=__LINE__, T...)(string fmt, lazy T args) nothrow { log2(file, line, LogLevel.info, fmt, args); }
/// ditto
void logWarn(string file=__FILE__, int line=__LINE__, T...)(string fmt, lazy T args) nothrow { log2(file, line, LogLevel.warn, fmt, args); }
/// ditto
void logError(string file=__FILE__, int line=__LINE__, T...)(string fmt, lazy T args) nothrow { log2(file, line, LogLevel.error, fmt, args); }

void timlog(string a, string file=__FILE__, int line=__LINE__) nothrow { log2(file, line, LogLevel.warn, "%s", a); }

/// ditto
version(none)
void log(T...)(LogLevel level, string fmt, lazy T args){
	log2(null, 0, level, fmt, args);
}

void log2(T...)(string file, int line, LogLevel level, string fmt, lazy T args)
nothrow {
	if( level < s_minLevel ) return;
	string pref;
	final switch( level ){
		case LogLevel.debug_: pref = "trc"; break;
		case LogLevel.diagnostic: pref = "dbg"; break;
		case LogLevel.info: pref = "INF"; break;
		case LogLevel.warn: pref = "WRN"; break;
		case LogLevel.error: pref = "ERR"; break;
		case LogLevel.fatal: pref = "FATAL"; break;
		case LogLevel.none: assert(false);
	}

	try {
		auto txt = appender!string();
		txt.reserve(256);
		import std.conv;
		if(file)
			txt~=text(file, ":", line," ");
		formattedWrite(txt, fmt, args);

		auto threadid = cast(ulong)cast(void*)Thread.getThis();
		auto fiberid = cast(ulong)cast(void*)Fiber.getThis();
		threadid ^= threadid >> 32;
		fiberid ^= fiberid >> 32;

		if (level >= s_minLevel) {
			File output;
			if (level == LogLevel.info) output = stdout;
			else output = stderr;
			if (output.isOpen) {
				output.writeln(txt.data);
				output.flush();
			}
		}
	} catch( Exception e ){
		// this is bad but what can we do..
		debug assert(false, e.msg);
	}
}

/// Specifies the log level for a particular log message.
enum LogLevel {
	debug_,
	diagnostic,
	info,
	warn,
	error,
	fatal,
	none
}

