"""Reference prototype of the Moonbase Commander simulation (see GAME_RULES.md).
NOT shipped and not committed. Use it to cross-check the GDScript simulation:
same cargo, plan rule and forced event days must give the same outcome, end day and stars.
Run:  python sim_prototype.py [path/to/constants.json]
Written on 9 Nov 2026 with Claude (AI) while designing the rules.
"""
import json, math, random
import sys, os
PATH=sys.argv[1] if len(sys.argv)>1 else os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','repo-files','game','data','constants.json')
C={k:x['value'] for k,x in json.load(open(PATH,encoding='utf-8'))['values'].items()}
def mass(c):
    return (c['solar']*C['SOLAR_UNIT_MASS_KG']+c['battery']*C['BATTERY_UNIT_MASS_KG']+c['reactor']*C['REACTOR_S_MASS_KG']
     +c['gh']*C['GREENHOUSE_KG_PER_M2']+c['o2']*C['O2_UNIT_MASS_KG']+c['water']*C['WATER_UNIT_MASS_KG']+c['food']*C['FOOD_CRATE_MASS_KG']+c['shield']*C['SHIELD_UNIT_KG'])
def shelter_dose(g):
    pts=C['SPE_SHIELD_TABLE_G_CM2']; ds=[C['SPE_DOSE_HABITAT_NO_EXTRA_MSV'],C['SPE_DOSE_SHIELD_5'],C['SPE_DOSE_SHIELD_10'],C['SPE_DOSE_SHIELD_15']]
    if g>=pts[-1]: return ds[-1]
    for i in range(len(pts)-1):
        if pts[i]<=g<=pts[i+1]:
            t=(g-pts[i])/(pts[i+1]-pts[i]); return ds[i]+t*(ds[i+1]-ds[i])
OUT={'REGOLITH','SCIENCE','CLEAN','REPAIR_PANEL'}
def run(c,rule,force,seed=1):
    if mass(c)>C['CARGO_LIMIT_KG']: return ('INVALID',0,0,{} )
    n=C['MISSION_CREW']; cap=c['battery']*C['BATTERY_UNIT_KWH']; batt=cap
    o2=c['o2']*C['O2_UNIT_KG']; water=c['water']*C['WATER_UNIT_KG']; food=c['food']*C['FOOD_CRATE_MASS_KG']
    co2=C['CO2_START_MMHG']; dust=C['DUST_LANDING']; g=c['shield']*C['SHIELD_UNIT_G_CM2']
    broken_rec=False; broken_pan=0; sick=[0]*n; ever_sick=False; dose=[0.0]*n; sci=0
    gh_alive=c['gh']>0; gh_since_farm=0; gh_wilt=0; gh_healthy=0
    storm=force.get('storm',12); recd=force.get('recycler',99); metd=force.get('meteoroid',0)
    log=[]
    for day in range(1,C['MISSION_DAYS']+1):
        sun=1.0 if day<C['SUNSET_DAY'] else (C['SUN_FACTOR_SUNSET_DAY'] if day==C['SUNSET_DAY'] else 0.0)
        st={'day':day,'sun':sun,'dust':dust,'g':g,'broken_rec':broken_rec,'broken_pan':broken_pan,'sick':sick,'gh':c['gh'],'gh_alive':gh_alive,'sci':sci}
        jobs,gh_on,sci_on=rule(st)
        shelter = (day==storm)
        if shelter: jobs=['REST']*n
        jobs=[('REST' if sick[i]>0 else j) for i,j in enumerate(jobs)]
        outside=[j in OUT for j in jobs]
        core=(C['LOAD_AIR_KW']+C['LOAD_THERMAL_KW']+C['LOAD_WASTE_KW']+C['LOAD_COMMS_KW'])
        req=[('CORE',core),('WATER',0 if broken_rec else C['LOAD_WATER_KW']),('FOOD',C['LOAD_FOOD_KW']),
             ('EVA',C['LOAD_EVA_KW'] if any(outside) else 0),('SCI',C['LOAD_OPS_KW'] if sci_on else 0),
             ('GH',C['GREENHOUSE_W_PER_M2']*c['gh']/1000 if (gh_on and c['gh']>0) else 0)]
        gen=(c['solar']-broken_pan)*C['SOLAR_UNIT_KW']*24*sun*(1-dust)+c['reactor']*C['REACTOR_S_KWE']*24
        left=gen+batt; served={}; shed=False
        for name,kw in req:
            if kw==0: served[name]=False if name!='WATER' else False; continue
            need=kw*24
            if not shed and need<=left: served[name]=True; left-=need
            else:
                if not shed: left=0  # partial use, battery drained
                shed=True; served[name]=False
        batt=min(cap,left)
        air=served['CORE']
        if not air: log.append((day,'BLACKOUT'))
        # greenhouse
        gh_o2=0
        if c['gh']>0 and gh_alive:
            healthy = served['GH'] and water>0 and gh_since_farm < C['FARM_EVERY_DAYS']
            if healthy:
                gh_wilt=0; gh_healthy+=1; gh_o2=C['CROP_O2_G_M2_DAY']*c['gh']/1000
                if gh_healthy % C['GREENHOUSE_DAYS_PER_POINT']==0: sci+=1
            else:
                gh_wilt+=1
                if gh_wilt>=2: gh_alive=False; log.append((day,'PLANTS_DIED'))
        # life
        co2 = max(C['CO2_START_MMHG'], co2-C['CO2_FALL_PER_DAY_AIR_ON']) if air else co2+C['CO2_RISE_PER_DAY_AIR_OFF']
        drink=C['WATER_KG_PERSON_DAY']*n; plants=C['GREENHOUSE_WATER_L_M2_DAY']*c['gh'] if served.get('GH') else 0
        rec_on=served['WATER'] and not broken_rec
        water-= (drink+plants)*((1-C['WATER_RECOVERY_FULL']) if rec_on else 1)
        need=C['O2_KG_PERSON_DAY']*n - gh_o2
        oga=min(max(need,0),C['OGA_O2_KG_DAY'],max(water,0)/C['OGA_WATER_PER_KG_O2']) if air else 0
        water-=oga*C['OGA_WATER_PER_KG_O2']; o2-= max(need-oga,0)
        eat=C['FOOD_PACKED_KG_PERSON_DAY']*n; food-=eat+(0 if served['FOOD'] else C['FOOD_SPOIL_DAYS_IF_OFF']*eat)
        # radiation
        for i in range(n): dose[i]+= C['RAD_SURFACE_MSV_DAY'] if (outside[i] and served['EVA']) else C['RAD_HABITAT_MSV_DAY']
        if day==storm:
            sd=shelter_dose(g); 
            for i in range(n): dose[i]+=sd
            if sd>C['RAD_SPE_LIMIT_MSV']: return ('EVAC_RADIATION',day,0,dict(sd=sd,log=log))
        if co2> C['CO2_HEADACHE_MMHG']:
            for i in range(n):
                if sick[i]==0: sick[i]=C['SICK_REST_DAYS']; ever_sick=True
        else:
            for i in range(n):
                if sick[i]>0 and jobs[i]=='REST': sick[i]-=1
        # end checks
        if co2>=C['CO2_EVAC_MMHG']: return ('EVAC_CO2',day,0,dict(log=log))
        if o2<0: return ('EVAC_O2',day,0,dict(log=log))
        if water<0: return ('EVAC_WATER',day,0,dict(log=log))
        if food<0: return ('EVAC_FOOD',day,0,dict(log=log))
        # jobs effects (tomorrow)
        nout=0
        for i,j in enumerate(jobs):
            if j in OUT and not served['EVA']: continue
            if j=='REPAIR_REC': broken_rec=False
            if j=='REPAIR_PANEL': broken_pan=max(0,broken_pan-1)
            if j=='REGOLITH': g+=C['REGOLITH_G_CM2_PER_JOB']
            if j=='SCIENCE' and served['SCI']: sci+=1
            if j=='FARM': gh_since_farm=-1
            if j in OUT and j!='CLEAN': nout+=1
        dust=min(C['DUST_MAX_LOSS'],dust+nout*C['DUST_PER_OUTSIDE_JOB'])
        if 'CLEAN' in jobs and served['EVA']: dust=0
        gh_since_farm+=1
        if day==recd: broken_rec=True; log.append((day,'RECYCLER_BROKE'))
        if day==metd and c['solar']-broken_pan>0: broken_pan+=1
    s1=1; s2=0 if ever_sick else 1; s3=1 if sci>=C['SCIENCE_GOAL_POINTS'] else 0
    stars=1+s2+(s2*s3)
    return ('SURVIVED',30,stars,dict(sci=sci,sick=ever_sick,water=round(water,1),o2=round(o2,1),food=round(food,1),g=g,dose=round(max(dose),1)))
# ---- plan rules used by the scenarios (GAME_RULES section 10) ----
def R_NOFIX(st): return (['REST']*4,False,False)
def R_REST(st):
    j=['REST']*4
    if st['broken_rec']: j[0]='REPAIR_REC'
    elif st['broken_pan']: j[0]='REPAIR_PANEL'
    return (j,False,False)
def R_SMART(st):
    dayt=st['day']<15
    j=['REST']*4
    if st['broken_rec']: j[0]='REPAIR_REC'
    elif st['broken_pan']: j[0]='REPAIR_PANEL'
    elif st['dust']>0.2: j[0]='CLEAN'
    j[1]='REGOLITH' if st['g']<15 else ('SCIENCE' if dayt else 'REST')
    j[2]='SCIENCE' if dayt else 'REST'
    j[3]='FARM' if st['gh']>0 and st['gh_alive'] else ('SCIENCE' if dayt else 'REST')
    return (j,True,dayt)
base=dict(solar=20,battery=4,reactor=2,gh=0,o2=2,water=4,food=5,shield=10)
def S(**k): d=dict(base); d.update(k); return d
sc=[('S01_solar_only',S(battery=10,reactor=0),R_REST,{'storm':10}),
('S02_two_reactors_rest',S(),R_REST,{'storm':10}),
('S03_one_reactor_careful',S(reactor=1),R_REST,{'storm':10}),
('S04_max_batteries',S(battery=60,solar=30,reactor=0),R_REST,{'storm':10}),
('S05_no_shield',S(shield=0),R_REST,{'storm':12}),
('S06_recycler_not_fixed',S(water=4),R_NOFIX,{'storm':10,'recycler':12}),
('S07_three_stars',S(solar=24,battery=6,gh=10),R_SMART,{'storm':12,'recycler':14,'meteoroid':20}),
('S08_overweight',dict(solar=40,battery=60,reactor=3,gh=20,o2=20,water=20,food=20,shield=20),R_REST,{}),
('S09_recycler_fixed',S(water=4),R_REST,{'storm':10,'recycler':12}),
]
for name,c,r,f in sc:
    res=run(c,r,f); print(name, round(mass(c)), res[:3], {k:v for k,v in res[3].items() if k!='log'}, res[3].get('log','')[:4] if isinstance(res[3],dict) else '')
