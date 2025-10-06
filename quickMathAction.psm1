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

function Split-Batch
{
param (
    [UInt64]$Size = [UInt64]::MaxValue,
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$InputObject
)
begin {
    $Batch = [Collections.Generic.List[object]]::new() # is faster as [Collections.ObjectModel.Collection[psobject]]
}
process {
    if ($Size) {
        if ($Batch.get_Count() -ge $Size) {
            ,@($Batch)
            $Batch = [Collections.Generic.List[object]]::new()
        }
        $Batch.Add($_)
    }
    else { # if no size is provided, any top array will be unrolled (remove batches)
        $_
    }
}
End {
    if ($Batch.get_Count()) {
        ,@($Batch)
    }
}
}



Set-Alias solve qalc

