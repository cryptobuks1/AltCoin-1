# AltCoin (library and simulator)

This altcoin package provide 3 main functionalities:

1.  Data acquisition: 
	* scrapes coinmarketcap.com for currency data as needed
	* stores datas in various data sinks: json, bson, sqlite
	* provides transfer of one data sink to another

2.  Dataset merging and subset capabilities
	* Merge data as acquired into an ever larger dataset
	* Persists holes in the data to be acquired as needed

3.  Simulation construct
	* Provides a simulation structure to facilitate testing currency trading algorithms over a given time span, allowing different trading strategies to be compared.
	* Test trading over all > 2000 currencies for any time span.

--

To generate the xcode packages, use
swift package generate-xcodeproj

