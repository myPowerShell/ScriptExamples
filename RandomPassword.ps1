
Function RandomPassword ($length) {

    $special = 33..46
    $numa = 48..57
    $alpha = 65..90 + 97..127
    $secretkey = get-random -count $length -input ($special + $numa + $alpha) |
        ForEach-Object -begin { $pword = $null } -process {$pword += [char]$_} -end {$pword}

    return $secretkey

}

RandomPassword(8)

