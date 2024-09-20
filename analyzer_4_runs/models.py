# what i need 
# - compare crashes found by afltriage (comparing time, execution, number of crashes founds)
# - compare fuzzer, execution speed, queue size, maps bit set? 
# - compare coverage, sut covered from queue

import pandas as pd
import uuid
import json
import os

CRASH_EXT = ".crash"

class Crash:
    # strategy used to triage crash
    triage_strategy           = None
    # result of the triaging strategy
    bucket_id                 = None
    # execution in which program crashed
    faulting_execution_number = None
    # time in which program crashed
    faulting_execution_time   = None
    # path of the file that contain the 
    # testcase that caused the crash
    reproducer_path           = None
    # path of the triaging report for 
    # this crash
    report_path               = None
    # function in which program crashed
    faulting_function         = None
    # testcase path during the triaging
    testcase                  = None
    # equivalent testcases path 
    # during the triaging
    testcases_equivalent      = None

    def __init__(self, json_report_path):
        self.report_path = json_report_path
        self.reproducer_path = os.path.splitext(json_report_path)[0]+CRASH_EXT
        with open(self.report_path, 'r') as report_file:
            report_data = report_file.read()
            report_data = json.loads(report_data)
            self.faulting_execution_number = int(report_data["report"]["faulting_execution_number"])
            self.faulting_execution_time = int(report_data["report"]["faulting_execution_time"])
            self.triage_strategy = report_data["bucket"]["strategy"]
            self.bucket_id = report_data["bucket"]["strategy_result"]
            self.faulting_function = report_data["report"]["faulting_function"]
            self.testcase = report_data["testcase"]
            self.testcases_equivalent = report_data["testcase_equivalent"]
    
    def __eq__(self, other):
        return self.bucket_id == other.bucket_id
    
    def __hash__(self):
        return hash(self.bucket_id)
    
    def __str__(self):
        return self.__repr__()
    
    def __repr__(self):
        return f"Crash({self.bucket_id})"

class Run:
    id                   = None
    fuzzer_stats_path    = None
    afl_banner           = None
    command_line         = None
    run_time             = None
    bitmap_cvg           = None
    bitmap_cvg_pcg       = None
    bitmap_cvg_2nd       = None
    bitmap_2nd_entries   = None
    amount_saved_crashes = None
    saved_crashes        = set()
    corpus_count         = None
    execs_per_sec        = None
    df_plot_data         = None

    def __init__(self, fuzzer_stats_path, plot_data_path, crashes_triaged_dir_path):
        self.fuzzer_stats_path = fuzzer_stats_path
        self.id = uuid.uuid4()
        self.df_plot_data = pd.read_csv(plot_data_path)
        with open(self.fuzzer_stats_path, 'r') as fuzzers_stats_file:
            tmp_stats_data = {}
            for line in fuzzers_stats_file.readlines():
                key, value = line.split(":")
                tmp_stats_data[key.strip()]=value.strip()
            
        self.afl_banner           =  tmp_stats_data["afl_banner"]   
        self.command_line         =  tmp_stats_data["command_line"]   
        self.run_time             =  tmp_stats_data["run_time"]   
        self.bitmap_cvg           =  tmp_stats_data["bitmap_cvg"]   
        self.bitmap_cvg_pcg       =  tmp_stats_data["bitmap_cvg_pcg"] if "bitmap_cvg_pcg" in  tmp_stats_data else None 
        self.bitmap_cvg_2nd       =  tmp_stats_data["bitmap_cvg_2nd"] if "bitmap_cvg_2nd" in  tmp_stats_data else None 
        self.bitmap_2nd_entries   =  tmp_stats_data["bitmap_2nd_entries"] if "bitmap_2nd_entries" in  tmp_stats_data else None 
        self.amount_saved_crashes =  tmp_stats_data["saved_crashes"]   
        self.corpus_count         =  tmp_stats_data["corpus_count"]   
        self.execs_per_sec        =  tmp_stats_data["execs_per_sec"] 

        for file in os.listdir(crashes_triaged_dir_path):
            if ".json" not in file:
                continue
            json_crash_report_path = os.path.join(crashes_triaged_dir_path, file)
            self.saved_crashes.add(Crash(json_crash_report_path))
    
    def __str__(self):
        repr =   f"Run {self.afl_banner}\n"
        repr +=  f" ├─ cmd: {self.command_line}\n"
        repr +=  f" ├─ Corpus count: {self.corpus_count}\n"
        repr +=  f" ├─ Saved crashes: {self.saved_crashes}\n"
        repr +=  f" ├─ Bitmap coverage: {self.bitmap_cvg}\n"
        repr +=  f" ├─ Bitmap coverage (pcguard): {self.bitmap_cvg_pcg}\n"
        repr +=  f" ├─ Bitmap coverage (2nd): {self.bitmap_cvg_2nd}\n"
        repr +=  f" |  └─ Entries      (2nd): {self.bitmap_2nd_entries}\n"
        repr +=  f" ├─ Exec/s: {self.execs_per_sec}\n"
        repr +=  f" └─ Runtime: {self.run_time}\n"
        repr +=  f"\n"
        return repr 

    def __repr__(self):
        return f"Run: {self.command_line}"
    

class Experiment:
    tag  = None
    runs = list() 
    def __init__(self, tag, runs):
        self.tag = tag
        self.runs = runs

    def __str__(self) -> str:
        repr =   f"Experiment {self.tag}\n"
        for run in self.runs:
            repr +=  f" | ├─ cmd: {run.command_line}\n"
            repr +=  f" | ├─ Saved crashes: {run.saved_crashes}\n"
            repr +=  f" | ├─ Bitmap coverage: {run.bitmap_cvg}\n"
            repr +=  f" | ├─ Bitmap coverage (pcguard): {run.bitmap_cvg_pcg}\n"
            repr +=  f" | ├─ Bitmap coverage (2nd): {run.bitmap_cvg_2nd}\n"
            repr +=  f" | | └─ Entries      (2nd): {run.bitmap_2nd_entries}\n"
            repr +=  f" | ├─ Exec/s: {run.execs_per_sec}\n"
            repr +=  f" | └─ Runtime: {run.run_time}\n"
            repr +=  f" | \n"
        repr +=  f" └────────────────────────────────────────────────\n"
        return repr 

    def __repr__(self) -> str:
        return f"Experiment: {self.tag} with {self.runs} runs"

class CompareService:
    def get_experiments_dataframe(self, *experiments):
        df_runs = pd.DataFrame([], columns=["experiment_tag", "execs_per_sec", "saved_crashes", 
                                       "run_time", "bitmap_cvg", "bitmap_cvg_pcg", "bitmap_cvg_2nd", 
                                       "bitmap_2nd_entries", "command_line"])
        
        df_crashes = pd.DataFrame([], columns=["run_id", "triage_strategy", "crash_id", 
                                               "faulting_execution_number", "faulting_execution_time", 
                                               "faulting_function", "testcase", "testcases_equivalent"])
        
        df_runs_plot_data = pd.DataFrame([])
        
        for experiment in experiments:
            for run in experiments.runs:
                new_row = {
                    'experiment_tag': experiment.tag, 
                    'execs_per_sec': run.execs_per_sec,
                    "saved_crashes": run.saved_crashes,
                    "run_time": run.run_time,
                    "bitmap_cvg": run.bitmap_cvg,
                    "bitmap_cvg_pcg": run.bitmap_cvg_pcg,
                    "bitmap_cvg_2nd": run.bitmap_cvg_2nd,
                    "bitmap_2nd_entries": run.bitmap_2nd_entries,
                    "id": run.id,
                    "command_line": run.command_line,
                }
                df_runs = df_runs.append(new_row, ignore_index=True)

                plot_data_run_df = run.df_plot_data
                plot_data_run_df["experiment_tag"] = experiment.tag
                plot_data_run_df["run_id"] = run.id
                df_runs_plot_data = pd.concat(df_runs_plot_data, plot_data_run_df)

                for crash in run.saved_crashes:
                    new_row = {
                        "run_id": run.id,
                        "triage_strategy": crash.triage_strategy,
                        "crash_id": crash.bucket_id,
                        "faulting_execution_number": crash.faulting_execution_number,
                        "faulting_execution_time": crash.faulting_execution_time,
                        "faulting_function": crash.faulting_function,
                        "testcase": crash.testcase,
                        "testcases_equivalent": crash.testcases_equivalent,
                    }
                    df_crashes = df_crashes.append(new_row, ignore_index=True)
        
        return df_runs, df_runs_plot_data, df_crashes
    



        

