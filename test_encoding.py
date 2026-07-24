def test():
    bad = 'ðŸ ¦'
    try:
        good = bad.encode('cp1252').decode('utf-8')
        print(f"cp1252: {good}")
    except:
        pass
    try:
        good = bad.encode('latin1').decode('utf-8')
        print(f"latin1: {good}")
    except:
        pass

test()
