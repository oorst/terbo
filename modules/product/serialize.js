export default function () {
  return {
    id: this.id,
    name: this.name,
    description: this.description,
    code: this.code,
    sku: this.sku,
    manufacturerId: this.manufacturer ? this.manufacturer.id : undefined,
    manufacturerCode: this.manufacturerCode,
    supplierId: this.supplier ? this.supplier.id : undefined,
    supplierCode: this.supplierCode,
    uomId: this.uom ? this.uom.id : undefined
    data: this.data,
    cost: this.cost,
    namedMarkupId: this.namedMarkup ? this.namedMarkup.id: undefined,
    markup: this.markup,
    gross: this.gross,
    net: this.net
  }
}
