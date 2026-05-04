# Activity Diagram — Kelola Pabrik

**Aktor:** Admin  
**Deskripsi:** Admin dapat menambah, mengubah, dan menghapus data pabrik yang menjadi sumber perca. Data pabrik digunakan sebagai dropdown saat Driver menginput stok perca.

```mermaid
flowchart TD
    Start(["●  Mulai"])
    OpenList["Buka halaman Daftar Pabrik"]
    LoadList["Muat daftar pabrik dari DB\n(tabel factories)"]
    ChooseAction{"Aksi\npengguna?"}

    %% Add
    OpenAddForm["Buka dialog Tambah Pabrik"]
    FillAddForm["Isi:\n- Nama pabrik\n- Alamat\n- No. Telp"]
    ValidateAdd{"Semua field valid?"}
    ShowAddError["Tampilkan pesan\nvalidasi error"]
    InsertFactory["INSERT ke tabel factories"]
    ShowAddSuccess["Tampilkan pesan berhasil\nRefresh daftar"]

    %% Edit
    SelectFactory["Pilih Pabrik"]
    OpenEditForm["Buka dialog Edit Pabrik\n(pre-fill data saat ini)"]
    FillEditForm["Ubah nama / alamat / no. telp"]
    ValidateEdit{"Semua field valid?"}
    ShowEditError["Tampilkan pesan\nvalidasi error"]
    UpdateFactory["UPDATE tabel factories"]
    ShowEditSuccess["Tampilkan pesan berhasil\nRefresh daftar"]

    %% Delete
    ConfirmDelete{"Konfirmasi\nhapus?"}
    DeleteFactory["DELETE dari tabel factories"]
    ShowDeleteSuccess["Tampilkan pesan berhasil\nRefresh daftar"]

    End(["◉  Selesai"])

    Start --> OpenList
    OpenList --> LoadList
    LoadList --> ChooseAction

    ChooseAction -->|"Tambah"| OpenAddForm
    OpenAddForm --> FillAddForm --> ValidateAdd
    ValidateAdd -->|Tidak| ShowAddError --> FillAddForm
    ValidateAdd -->|Ya| InsertFactory --> ShowAddSuccess --> LoadList

    ChooseAction -->|"Edit"| SelectFactory
    SelectFactory --> OpenEditForm --> FillEditForm --> ValidateEdit
    ValidateEdit -->|Tidak| ShowEditError --> FillEditForm
    ValidateEdit -->|Ya| UpdateFactory --> ShowEditSuccess --> LoadList

    ChooseAction -->|"Hapus"| SelectFactory
    SelectFactory --> ConfirmDelete
    ConfirmDelete -->|Tidak| LoadList
    ConfirmDelete -->|Ya| DeleteFactory --> ShowDeleteSuccess --> LoadList

    LoadList --> End
```

## Langkah-langkah

| # | Aksi | Keterangan |
|---|---|---|
| 1 | Lihat daftar | Daftar pabrik dimuat dari tabel `factories` |
| 2 | Tambah | Form dialog → validasi → INSERT ke `factories` |
| 3 | Edit | Pre-fill form dengan data saat ini → validasi → UPDATE `factories` |
| 4 | Hapus | Konfirmasi → DELETE dari `factories` |

> **Catatan:** Menghapus pabrik yang sudah terhubung dengan data `percas_stock` akan gagal karena ada foreign key constraint di database.
