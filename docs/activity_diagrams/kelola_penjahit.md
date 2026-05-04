# Activity Diagram — Kelola Penjahit

**Aktor:** Admin  
**Deskripsi:** Admin dapat menambah, mengubah, melihat detail, dan menghapus data penjahit. Setiap penjahit memiliki foto profil yang disimpan di Supabase Storage.

```mermaid
flowchart TD
    Start(["●  Mulai"])
    OpenList["Buka halaman Daftar Penjahit"]
    LoadList["Muat daftar penjahit dari DB\n(tabel tailors, paginated)"]
    SearchOrBrowse{"Aksi\npengguna?"}

    %% Search
    SearchInput["Input kata kunci pencarian"]
    SearchDB["Query DB: tailors.ilike('name', '%query%')"]
    DisplayResults["Tampilkan hasil pencarian"]

    %% Add
    OpenAddForm["Buka form Tambah Penjahit"]
    FillAddForm["Isi nama, no. telp, alamat\n(opsional: foto)"]
    HasPhotoAdd{"Ada foto?"}
    UploadPhotoAdd["Upload foto ke Supabase Storage\n(bucket: majunkita/tailor_images/)"]
    InsertTailor["INSERT ke tabel tailors"]
    ShowAddSuccess["Tampilkan pesan berhasil\nRefresh daftar"]

    %% Edit
    SelectTailor["Pilih Penjahit"]
    OpenEditForm["Buka form Edit Penjahit"]
    FillEditForm["Ubah data:\nnama / no. telp / alamat / foto"]
    HasNewPhoto{"Ada foto baru?"}
    DeleteOldPhoto["Hapus foto lama\ndari Storage"]
    UploadNewPhoto["Upload foto baru\nke Storage"]
    UpdateTailor["UPDATE tabel tailors"]
    ShowEditSuccess["Tampilkan pesan berhasil\nRefresh daftar"]

    %% Detail
    ViewDetail["Tampilkan detail penjahit:\nstok perca, saldo upah,\nReff, prediksi majun"]

    %% Delete
    ConfirmDelete{"Konfirmasi\nhapus?"}
    DeletePhoto["Hapus foto dari Storage\n(jika ada)"]
    DeleteRecord["DELETE dari tabel tailors"]
    ShowDeleteSuccess["Tampilkan pesan berhasil\nRefresh daftar"]

    End(["◉  Selesai"])

    Start --> OpenList
    OpenList --> LoadList
    LoadList --> SearchOrBrowse

    SearchOrBrowse -->|"Cari"| SearchInput
    SearchInput --> SearchDB --> DisplayResults --> SearchOrBrowse

    SearchOrBrowse -->|"Tambah"| OpenAddForm
    OpenAddForm --> FillAddForm --> HasPhotoAdd
    HasPhotoAdd -->|Ya| UploadPhotoAdd --> InsertTailor
    HasPhotoAdd -->|Tidak| InsertTailor
    InsertTailor --> ShowAddSuccess --> LoadList

    SearchOrBrowse -->|"Lihat / Edit"| SelectTailor
    SelectTailor --> OpenEditForm
    OpenEditForm --> ViewDetail
    OpenEditForm --> FillEditForm
    FillEditForm --> HasNewPhoto
    HasNewPhoto -->|Ya| DeleteOldPhoto --> UploadNewPhoto --> UpdateTailor
    HasNewPhoto -->|Tidak| UpdateTailor
    UpdateTailor --> ShowEditSuccess --> LoadList

    SearchOrBrowse -->|"Hapus"| SelectTailor
    SelectTailor --> ConfirmDelete
    ConfirmDelete -->|Tidak| LoadList
    ConfirmDelete -->|Ya| DeletePhoto --> DeleteRecord --> ShowDeleteSuccess --> LoadList

    LoadList --> End
```

## Langkah-langkah

| # | Aksi | Keterangan |
|---|---|---|
| 1 | Lihat daftar | Daftar penjahit dimuat dengan paginasi dari tabel `tailors` |
| 2 | Cari | Filter real-time dengan `ilike` di kolom `name` |
| 3 | Tambah | Form isi data + opsional foto → INSERT ke `tailors` |
| 4 | Edit | Ubah data → jika foto baru ada, foto lama dihapus dari Storage |
| 5 | Lihat detail | Menampilkan statistik: stok perca, saldo, Reff, prediksi majun |
| 6 | Hapus | Konfirmasi → hapus foto dari Storage → DELETE dari `tailors` |
