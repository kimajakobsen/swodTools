import argparse
import glob
import re
import difflib
import prettytable
from common.log import Log

#patterns = ['snowflakeschema','starschema', 'denormalizedschema']
#scalefactors = ['0.1']
#seeds = ['1','2','3','4','5']



def required_length(nmin,nmax):
		class RequiredLength(argparse.Action):
				def __call__(self, parser, args, values, option_string=None):
						if not nmin<=len(values)<=nmax:
								msg='argument "{f}" requires between {nmin} and {nmax} arguments'.format(
										f=self.dest,nmin=nmin,nmax=nmax)
								raise argparse.ArgumentTypeError(msg)
						setattr(args, self.dest, values)
		return RequiredLength

def initilize_logs(patterns,scalefactors,seeds):
	logfiles = []
	global logFileDirectory
	for scalefactor in scalefactors:
		for seed in seeds:
			for pattern in patterns:
				logfiles.append(Log.find_logfile(pattern,scalefactor,seed,logFileDirectory))
	return logfiles

def parse_arguments():
	global patterns
	global seeds
	global scalefactors
	global logFileDirectory
	parser = argparse.ArgumentParser(description='Compare results of logfiles e.g. --pattern snowflakeschema starschema denormalizedschema --scale 0.5 --seed 5 --system virtuoso_open-source_7.1 ')
	parser.add_argument('--pattern', metavar='pattern', type=str, nargs='+', action=required_length(2,3), dest='patterns', required=True , help='enter at least two patterns (space seperated) e.g. snowflakeschema')
	parser.add_argument('--seed', metavar='seed', type=str, nargs='+', dest='seeds', required=True , help='enter at least one seed (space seperated) e.g. 99')
	parser.add_argument('--scale', metavar='scalefactor', type=str, nargs='+', dest='scalefactors', required=True , help='enter at least one scale (space seperated) e.g. 0.5')
	parser.add_argument('--system', metavar='name', type=str, nargs='+', dest='system', required=True , help='enter the name of the DBRMS e.g. virtuoso_open-source_7.1')
	args = parser.parse_args()
	patterns = args.patterns
	seeds = (args.seeds)
	scalefactors = (args.scalefactors)
	logFileDirectory = "logs/dbserver1/"+args.system[0]


def __compare_results(log1,log2):
	results = {}
	results[0] = log1.get_pattern()+'_'+log1.get_scale()+'_'+log1.get_seed()+"--"+log2.get_pattern()+'_'+log2.get_scale()+'_'+log2.get_seed()
	for i in range(1,len(log1.get_results())+1):
		if log1.get_result(i) != log2.get_result(i):
			results[i] = "Missmatch"
		#	print log1.get_filepath()
		#	print log1.get_result(i)
			
		#	print "\n"
		#	print log2.get_filepath()
		#	print log2.get_result(i)
		#	sys.exit()

			
		else:
			results[i] = ""
	return results

def create_ascii_table(columns):
	table = prettytable.PrettyTable()
	columns.insert(0,{0:"",1:"Q1",2:"Q2",3:"Q3",4:"Q4",5:"Q5",6:"Q6",7:"Q7",8:"Q8",9:"Q9",10:"Q10",11:"Q11",12:"Q12",13:"Q13",14:"Q14",15:"Q15",16:"Q16",17:"Q17",18:"Q18",19:"Q19",20:"Q20",21:"Q21",22:"Q22"})
	
	for column in columns:
		table.add_column(column[0],column)
	return table

def compare_all_results(log1, log2, log3 = None):
	try:
		if log1.get_seed() != log2.get_seed():
			raise TypeError('logfiles are not comparable, the seed differs',log1,log2)
		elif log1.get_scale() != log2.get_scale():
			raise TypeError('logfiles are not comparable, the scalefactor differs',log1,log2)
		elif log1.get_results().keys().sort() != log2.get_results().keys().sort():
			raise TypeError('logfiles are not comparable, the number of results or which results it contains differs',log1,log2)
		elif log3 != None:
			if log2.get_seed() != log3.get_seed():
				raise TypeError('logfiles are not comparable, the seed differs',log2,log3)
			elif log2.get_scale() != log3.get_scale():
				raise TypeError('logfiles are not comparable, the scalefactor differs',log2,log3)
			elif log2.get_results().keys().sort() != log3.get_results().keys().sort():
				raise TypeError('logfiles are not comparable, the number of results or which results it contains differs',log2,log3)
	except TypeError as err:
		print(err.args)

	columns = []
	columns.append(__compare_results(log1,log2))
	if log3 != None:
		columns.append(__compare_results(log1,log3))
		columns.append(__compare_results(log2,log3))
	return create_ascii_table(columns)

	

parse_arguments()
logfiles = initilize_logs(patterns, scalefactors, seeds)

for i in range(1,len(seeds)*len(scalefactors)+1):
	log1 = logfiles.pop()
	log2 = logfiles.pop()
	log3 = logfiles.pop()
	print compare_all_results(log1,log2,log3)


