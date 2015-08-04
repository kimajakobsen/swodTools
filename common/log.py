import os.path
import sys
import re
import glob

class Log:
	
	def __init__(self,logfile):
		if os.path.isfile(logfile) == False:
			sys.exit(logfile+" is not a file")

		logfileSplit = logfile.split('/').pop().split('_')

		self.pattern = logfileSplit[2]
		self.scale = logfileSplit[3]
		self.seed = logfileSplit[4]
		self.results = {k+1: "" for k in range(22)}
		self.queryTimes = {k+1: "" for k in range(22)}
		self.logFile = logfile
		self.__logFileResultsRead = False
		self.__logFileQueryTimesRead = False

	@classmethod
	def find_logfile(cls, pattern,scale,seed,logFileDirectory):
		AsortedLogFiles = glob.glob(logFileDirectory+'/run_lineitem-cube_'+pattern+'_'+scale+'_'+seed+'_'+'*.log')
		newestLogFile = sorted(AsortedLogFiles).pop()


		return cls(newestLogFile)

	def __repr__(self):
		return self.pattern+'_'+self.scale+'_'+self.seed



	def __read_logfile_results(self,logfile):
		pattern = re.compile('{queryname:[0-9][0-9]?')
		with open(logfile) as infile:
			copy = False
			for line in infile:
				if pattern.match(line.strip()):
					querynumber = line.strip()[11:-1]
					copy = True
				elif line.strip() == "__________________________________________________________________________________":
					copy = False
				elif copy:
					self.results[int(querynumber)]+=line    

	def __read_logfile_query_times(self,logfile):
		queryTimesRaw = ""

		pattern = re.compile('Average:')
		timeout = re.compile('header:[timeout],')
		with open(logfile) as infile:
			for line in infile:
				if pattern.match(line.strip()):
					queryTimesRaw+=line[10:]
		split = re.split(r'\t+',re.sub('\n','', queryTimesRaw))
		split.pop()
		split.pop()
		split.pop()
		for key, value in self.queryTimes.iteritems():
			self.queryTimes[key] = split[key-1]
			if "header:[timeout]" in self.get_result(key):
				self.queryTimes[key] = 1000
	def add_result(self, number,result):
		self.results[number] = result

	def get_result(self, number):
		if self.__logFileResultsRead:
			return self.results[number]
		else:
			self.__read_logfile_results(self.logFile)
			self.__logFileResultsRead = True
			return self.results[number]

	def get_query_times(self):
		if self.__logFileResultsRead:
			return self.queryTimes
		else:
			self.__read_logfile_query_times(self.logFile)
			self.__logFileQueryTimesRead = True
			return self.queryTimes

	def get_results(self):
		if self.__logFileResultsRead:
			return self.results
		else:
			self.__read_logfile_results(self.logFile)
			self.__logFileResultsRead = True
			return self.results

	def get_pattern(self):
		return self.pattern

	def get_scale(self):
		return self.scale

	def get_seed(self):
		return self.seed

        def get_filepath(self):
		return self.logFile
