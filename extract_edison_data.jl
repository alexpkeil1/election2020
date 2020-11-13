# a program to extract Edison data from NYT website on 2020 US Presidential election
using JSON, JSONTables, DataFrames, CSV, Dates, HTTP, Printf


function readNYT(state="pennsylvania")
  # pull data from NYT website in json format
  dict2 = Dict()
  st = "https://static01.nyt.com/elections-assets/2020/data/api/2020-11-03/race-page/$state/president.json"
  HTTP.open(:GET, st) do f
      dicttxt = read(f,String)  # file information to string
      dict2 = JSON.parse(dicttxt)  # parse and transform data
  end
  dict2
end

function write_lines(res, fl; mode="a")
  # arbitrary vector -> comma separate string -> line in a csv file
  if typeof(res)==Array{Symbol,1}
    outtext = join([String(a) for a in res], ",")
  else
    outtext = join(["$a" for a in res], ",")
  end
  open(fl, mode) do io
     write(io, outtext*"\n")
  end;
end


function tocsv(series, state;resfile="/tmp/votes.txt", mode="w")
  # hacky function to extract tabular data from json data
  if mode == "w" 
    nms = ["state", "total_votes", "date", "time", "source", "biden_votes", "trump_votes", 
           "thirdparty_votes", "biden_share", "trump_share", "thirdparty_share"]
    write_lines(nms, resfile, mode="w")
  end
  for ff in series
    votes = ff["votes"]
    dtt = DateTime(ff["timestamp"][1:(end-1)])
    date = Date(dtt)
    time = Time(dtt)
    source = ff["eevp_source"]
    biden = 0.
    trump = 0.
    third = 0.
    bidenshare = 0.
    trumpshare = 0.
    thirdshare = 0.
    for candidate in ff["vote_shares"]
      share = candidate[2]
      if candidate[1] == "bidenj"
        bidenshare += share
        biden += round(votes*share, digits=3)
      elseif candidate[1] == "trumpd"
        trumpshare += share
        trump += round(votes*share, digits=3)
      end
      thirdshare = (bidenshare + trumpshare) == 0.0 ? 0.0 : round(1.0 - bidenshare - trumpshare, digits=3) 
      third += round(votes*share, digits=3)    
    end
    res = hcat(state, votes, date, time, source, @sprintf("%.3f", biden), @sprintf("%.3f", trump), 
               @sprintf("%.3f", third), bidenshare, trumpshare, thirdshare)
    write_lines(res, resfile, mode="a")
  end
end

function readallNYT(state="pennsylvania";resfile = "/tmp/voting.txt", mode="w")
  # wrapper function to write csv for a state
  fd = readNYT(state)
  series = fd["data"]["races"][1]["timeseries"]
  tocsv(series, state, resfile = resfile, mode=mode)
end

function main(outfile)
  # wrapper function to write csv for all states + DC
  nytstates = ["alabama", "alaska", "arizona", "arkansas", "california", "colorado", "connecticut", "delaware", 
       "district-of-columbia", "florida", "georgia", "hawaii", "idaho", "illinois", "indiana", "iowa", 
       "new-jersey", "kansas", "kentucky", "louisiana", "maine", "maryland", "massachusetts", "new-mexico", 
       "michigan", "minnesota", "mississippi", "missouri", "montana", "nebraska", "nevada", "new-hampshire", 
       "new-york", "north-carolina", "north-dakota", "ohio", "oklahoma", "oregon", "pennsylvania", "rhode-island", 
       "south-carolina", "south-dakota", "tennessee", "texas", "utah", "vermont", "virginia", "washington", 
       "west-virginia", "wisconsin", "wyoming"]
  for (i,s) in enumerate(nytstates)
    println("$s")
    try
      readallNYT(s, resfile = outfile, mode= i == 1 ? "w" : "a")
    catch
      println("Not found")
    end
  end
end

main(homedir()*"/repo/election2020/edison_json_data_nyt.csv")
