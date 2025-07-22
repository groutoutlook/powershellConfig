# Import-Module -Name Prelude
function toHex($number) {
    Write-Output('{0:X}' -f $number)
}

function toBin($number) {
    Write-Output('{0:B}' -f $number)
}


function Format-ArrayFromString() {
    $finalArray = @()
    $args -split "," | % { $finalArray += iex $_ }
    return $finalArray
}

function Format-ReverseArray() {
    $returnArray = @()
    $array = $args -split "," 
    [array]::Reverse($array); 
    $returnArray = $array
    return $returnArray
}

function reverse { 
    param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false)
        ]
        [String[]] $inputArr,

        [Parameter()]
        [String] $delimiter = ","
    )
    $arr = @($inputArr)
    [array]::reverse($arr)
    [string]$resarr = $arr -join $delimiter
    echo $resarr
}
