---
title: "Go: Easy data transformations via composition"
date: "2019-03-11T09:31:27+01:00"
categories:
  - development
tags:
  - golang
  - json
  - api
---

I enjoy writing *Go*. It lacks the magic and obfuscation present in other languages, whilst possessing an intuitive syntax that still allows the concise expression of complex ideas. It's awesome.

What's less awesome, unfortunately, is that the flexibility of the language often leads to it's simplicity being overlooked; and this is no more apparent than in *data transformation layers*. If you find yourself regularly writing convulated transformers, then there's a good chance that *you're not actually understanding the language properly*.

And what's the point in writing Go if you're simply going to write Java/C#/PHP?

## Generating API Responses

It's a common scenario: you have an object of type `A`, and actually you really need an object of type `T`. This is inevitable in many scenarios but especially with microservices and the layer between data persistence (i.e your database), and transport (i.e http request/response management).

As an example, say you maintain a small service that is responsible for workplace complaints[^1]; it has an entity named `Dispute`, and two different types of user - `Manager`, and `Respondent`. Whilst a `Manager` should be able to see the entirety of the complaint, obviously there should be certain properties hidden from the `Respondent` (i.e subject of the complaint).

```json
{
    "sender":  employeeId,
    "respondent": employeeId,
    "dispute_date": date,
    "logged_date": date,
    "dispute_title: string,
    "dispute_body": string,
    "requested_action": string,
    "taken_action": string
}
```

Given the entity described above, it seems fair to provide the `Respondent` with (1) the date the event occurred, (2) the title of the dispute, and (3) the description of the dispute. So how should we manage this?

### Struct embedding and composition

The solution isn't maintaining *duplicate* structs: it's about *composing* structs in such a way that they facilitate the different data access requirements relevant to your domain. An idiomatic way of resolving this is via *struct embedding*, providing a flexible way of composing structs.

```go
type DisputeEvent struct {
    Date *time.Date  `json:"dispute_date"`
    Title string     `json:"dispute_title"`
    Body  string     `json:"dispute_body"`
}

type Dispute struct {
    DisputeEvent
    Sender          EmployeeId  `json:"sender"`
    Respondent      EmployeeId  `json:"respondent"`
    LoggedDate      *time.Date  `json:"logged_date"`
    RequestedAction string      `json:"requested_action"`
    TakenAction     string      `json:"taken_action"`
    IsResolved      bool        `json:"resolved"`
}

respondentPayload, _ := json.Marshal(dispute.DisputeEvent);
managerPayload, _ := json.Marshal(dispute)
```

As the example above shows, by composing our structs this way we can simply target an embedded struct - in our case `DisputeEvent` - if we need to provide a version with less properties.

Not only is this a more idiomatic method, one that doesn't require any convulated transformations, but it also (a) removes the need for custom queries to retrieve specific fields from any database, and (b) prevents any internal components from needing awareness of the different types of output - they only need to be able to operate on a `Dispute` entity.

If your use case is *particularly trivial* though, then it also becomes possible to inline your response struct - although this is probably a *code smell*, and you should aim to compose your structs correctly:

```go
json.Marshal(struct {
    Resolved        bool        `json:"resolved"`
    DateLodged      *time.Date  `json:"submission_date"`
    DisputeTitle    string      `json:"title"`
}{
    dispute.IsResolved, dispute.LoggedDate, dispute.Title
})
```

### Using Composition to Combine Data Sources

When composition is applied correctly, it can also prove to be useful if you need to combini multiple data sources. For example; if you were implementing an invoicing service then you may need to query an external API endpoint responsible for an `Account` entity, whilst you retrieve an `Invoice` entity from a local database.

```json
{
    "account_id"    : string,
    "username"      : string,
    "company_name"  : string,
    "amount"        : string,
    "entries"       : [ object, object ... ],
    "due_date"      : date,
    "paid"          : bool
}
```

Whilst you're able to get `account_id`, `username`, and `company_name` from the Account API response, the other properties must come from the database. We've already seen how to use composition to generate a JSON payload with *reduced* attributes, but how could we do generate a JSON object with *additional* attributes - i.e combined data sources?


```go
/* Define the properties to be taken from the Account API */
type InvoiceAccount struct {
    ID string `json:"account_id"`
    Username string `json:"username"`
    CompanyName string `json:"company_name"`
}

/* Define the properties required from the Invoice DB */
type InvoiceEntry struct { ... }
type InvoiceSummary struct {
    Amount string `json:"amount",gorm:"column:amount"`
    Entries []InvoiceEntry `json:"entries",gorm:"column:entries"`
    Due *time.Date `json:"due_date",gorm:"column:due_date"`
    IsPaid bool `json:"paid",gorm:"column:is_paid"`
}

/* Create a Response struct which embeds both the Invoice and the Account properties */
type InvoiceResponse struct{
    InvoiceAccount
    InvoiceSummary
}

invoiceResponse := &InvoiceResponse{}

/* Populate invoiceResponse.InvoiceSummary from the database */
db.First(invoiceResponse.InvoiceSummary, 1)

/* Populate invoiceResponse.InvoiceAccount from the Account API response */
json.Unmarshal([]byte(accountsApiResponse), invoiceResponse.InvoiceAccount)

/* Marshal the entire InvoiceResponse struct */
json.Marshal(invoiceResponse)

```

As this example shows, struct embedding is the perfect option for combining data from multiple sources. In the event that one of your sources contains additional/sensitive information, then you use an adaption of the previous technique to filter this data.

## Handling Inbound Data

Another common issue - especially where code generation tools are employed (i.e Swagger) - is when you *receive* data; many developers marshal *all available data* in to a struct. Whilst this may not seem like a big problem, this can cause issues where there's a lot of data to process.

Consider an example where we're *acting as the consumer* of a third party API; we're responsible for an ecommerce platform that generates thousands of orders daily, but we need to run a reconciliation task every 24 hours that requests all payments from an external API, and proceeds to check them against the status of any associated order.

The response we recieve from the Payment API may look something like this:

```json
    {
        payments: [{
            "payment_id": string,
            "recipient": object,
            "debtor": object,
            "amount": string,
            "method": string,
            "payment_events": [{
                "successful": bool,
                "time": time,
                "status_code": string,
                "processor_description": string
            } ... ]
        }, ... ]
        }

```

To parse the this JSON object, we would likely have a set of structs that are structured something like this:

```go
type PaymentRecipient { ... }
type PaymentDebtor { ... }

type PaymentEventList struct {
    Events []PaymentEvent `json:"payment_events"`
}

type PaymentEvent struct {
    IsSuccess   bool        `json:"successful"`
    Time        *time.Time  `json:"time"`
    Status      string      `json:"status_code"`
    Description string      `json:"processor_description"`
}

type Payment struct {
    PaymentEventList
    ID          string              `json:"payment_id"`
    Amount      string              `json:"amount"`
    Recipient   PaymentRecipient    `json:"recipient"`
    Debtor      PaymentDebtor       `json:"debtor"`
    Method      string              `json:"method"`
}
```

Yet our use case only requires (1) the ID of the payment, and (2) the events related to that payment. Whilst we could simply marshal the entire response object in to a Payment struct, this would be *very bad* for performance and resource utilisation; for every payment processed we'd have to allocate the memory - and subsequently unmarshal all the properties - for an entire struct when *we only need two properties*.

Considering that use cases like this one are also likely to rely upon concurrency, we may be looking at multiple threads/goroutines requesting memory allocation for potentially thousands of structs.

So using the same technique as when we *combined* and *filtered* outgoing JSON responses, we can also filter out incoming JSON objects. For example - to *only* retrieve the `payment_events` and `payment_id` - we could write something like this:

```go
type PaymentReconciliationData {
    PaymentEventList,
    ID string `json:"payment_id"`
}

reconciliationData := &PaymentReconciliationData{}
json.Unmarshal([]byte(responseJson), reconciliationData)
```

This results in a struct that has all the properties we need, but doesn't require the memory allocation of a struct that contains *more* than the properties we need.

## What if you're not working with JSON?

There's no real mechanism to convert one struct - of type `A` - to another struct - of type `B`; unless they have an indentical underlying structure - with the same type of fields, declared in the same order. If this is your use case (and if it is, once again... something isn't quite right!) then you can do a conversion this way:

```go

type A struct {
    Num int
}

type B struct {
    Num int
}

// a is of type 'A'
a := A{Num: 5}

// b is of type 'B', with the contents of 'a'
b := B(a)

```

Another method is to take advantage of the JSON mapping properties, and simple Marshal the original data struct, and Unmarshal it in to your desired data struct. This can be facilitated by ensuring that the `json:"..."` tags are matching on both structs.

```go

func ConvertStruct(from interface{}, to *interface{}) interface{} {
    map := json.Marshal(from)
    json.Unmarshal(map, to)
    return to
}

struct InputMessage {
    Message     string `json:"message"`
    From        string `json:"from"`
    Successful  string `json:"success"`
}

struct OutputMessage {
    Message string `json:"message"`
    From    string `json:"from"`
}

input := InputMessage{
    Message: "Hello World!",
    From: "Fergus In London",
    Successful: true,
}

output := &OutputMessage{}
ConvertStruct(input, output)
```

This approach can also take advantage of `UnmarshalJSON()` and `MarshalJSON()`, to override the conversion of specific attributes: this is a concise and flexible - albeit likely not performent - mechanism to convert structs.

Unfortunately, it's not unlikely that the `json` tags don't match on your structs, and that you're not able to modify one of them. In which case, you're likely stuck with good ol' manual conversions:

```go
type A struct {
    Name                string
    Email               string
    Age                 int
    Location            string
    PrivacyPermission   bool
}

type B struct {
    Name string
    Age  int
    Email string
}

func NewBFromA(input A) B {
    return B{
        Name: input.Name,
        Age: input.Age,
        Email: input.Email
    }
}
```

## Conclusion

Developers new to Go - especially those coming from languages without a type system - often seem to think that data transformation is made more difficult as a result of strict typing. This really isn't true, and with a few basic techniques data transformation can be easy, safe, and concise.

[^1]: This is such a bizarre example: as way of an explanation - I was working on a HR platform when this post was written.
