export const hexEncode = function(value: string){
    let hex, i;

    let result = "";
    for (i=0; i<value.length; i++) {
        hex = value.charCodeAt(i).toString(16);
        result += ("000"+hex).slice(-4);
    }

    return result
}
export const hexDecode = function(value: string){
    const hexes = value.match(/.{1,4}/g) || [];
    let back = "";
    for(let j = 0; j<hexes.length; j++) {
        back += String.fromCharCode(parseInt(hexes[j], 16));
    }

    return back;
}