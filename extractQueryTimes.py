import time
import argparse
import csv
import math
import subprocess
import prettytable
import sys
from common.log import Log
from collections import defaultdict

logfilepaths = ""
queryTimes = defaultdict(list)

def parse_arguments():
	global logfilepaths
	parser = argparse.ArgumentParser(description='Extract the query times from logfiles and calculate average and geometric mean')
	parser.add_argument('logfiles', metavar='logfile', type=str, nargs='+', help='enter path to logfiles or folder containing logfiles')
	args = parser.parse_args()
	logfilepaths = (args.logfiles)

def nroot(x, n):
	return math.pow(x, 1.0/n)

def calculate_average(queryTimes):
	result = defaultdict(list)

	for key, patternScaleSet in queryTimes.iteritems():
		tempQueryTimeSet = {k+1: [] for k in range(22)}
		if len(patternScaleSet) < 3:
			sys.exit("insufficient logs of type "+key+" has been supplied. A minimum of three is needed.")

		for queryTimeSet in patternScaleSet:
			for queryNumber, queryTime in queryTimeSet.iteritems():
				if queryNumber != 'avg' and queryNumber != 'geo':
					tempQueryTimeSet[queryNumber].append(queryTime)

		avgQueryTimes = {k+1: [] for k in range(22)}
		for rowNumber, row in tempQueryTimeSet.iteritems():
			for i in range(0,len(row)):
				if row[i] == '    ':
					row[i] = 1000
			row = map(float, row)
			row.sort()
			del row[0]
			del row[-1]
			avgQueryTimes[rowNumber] = sum(row)/len(row)

			avgQueryTimeProduct = 1.0
			avgQueryTimeSum = 0
		for j, avgQueryTime in avgQueryTimes.iteritems():
			avgQueryTimeProduct*=(avgQueryTime)
			avgQueryTimeSum+=(avgQueryTime)
		avgQueryTimes["avg"] = avgQueryTimeSum/22
		avgQueryTimes["geo"] = nroot(avgQueryTimeProduct,22)		
		result[key].append(avgQueryTimes)
	return result	

parse_arguments()

# create data structure
for logfilepath in logfilepaths: 
	log = Log(logfilepath)
	queryTimes[log.get_pattern()+log.get_scale()].append(log.get_query_times())

	
for key, patternScaleSet in queryTimes.iteritems():
	print key
	csvbody = []
	csvbody.append(["Q1","Q2","Q3","Q4","Q5","Q6","Q7","Q8","Q9","Q10","Q11","Q12","Q13","Q14","Q15","Q16","Q17","Q18","Q19","Q20","Q21","Q22","Avg","Geo. mean"])
	
	patternScaleSet.append(calculate_average(queryTimes)[key].pop()) #add avg results
	
	for queryTimeSet in patternScaleSet:
		tempList = []
		for i, queryTimeList in queryTimeSet.iteritems():
			tempList.append(queryTimeList)
		if len(tempList) != 24:
			tempList+=["",""]
		csvbody.append(tempList)
	with open('logs/dbserver1/virtuoso_open-source_7.1/'+key+"_"+(time.strftime("%H:%M:%S-%d:%m:%Y"))+'.csv', 'w+') as fp:
		a = csv.writer(fp, delimiter=',')
		a.writerows(zip(*csvbody))

	x = prettytable.PrettyTable()
	for row in zip(*csvbody):
		x.add_row(row)
	print x









